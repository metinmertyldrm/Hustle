BEGIN;

CREATE TABLE app_users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email varchar(320) NOT NULL UNIQUE,
    password_hash text NOT NULL,
    display_name varchar(120),
    preferred_currency char(3) NOT NULL DEFAULT 'USD',
    status varchar(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','suspended','deleted')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE assets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    symbol varchar(30) NOT NULL,
    name varchar(160) NOT NULL,
    asset_type varchar(20) NOT NULL CHECK (asset_type IN ('crypto','stock','fund')),
    exchange varchar(50) NOT NULL,
    quote_currency varchar(10) NOT NULL DEFAULT 'USD',
    is_active boolean NOT NULL DEFAULT true,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (exchange, symbol)
);

CREATE TABLE watchlists (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    name varchar(100) NOT NULL,
    is_default boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, name)
);

CREATE UNIQUE INDEX ux_watchlists_one_default ON watchlists(user_id) WHERE is_default;

CREATE TABLE watchlist_items (
    watchlist_id uuid NOT NULL REFERENCES watchlists(id) ON DELETE CASCADE,
    asset_id uuid NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    added_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (watchlist_id, asset_id)
);

CREATE TABLE alert_rules (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    asset_id uuid NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    name varchar(120) NOT NULL,
    expected_action varchar(20) NOT NULL CHECK (expected_action IN ('SAFE_BUY','TAKE_PROFIT')),
    timeframe varchar(10),
    min_confidence numeric(5,4) NOT NULL DEFAULT 0.6000 CHECK (min_confidence BETWEEN 0 AND 1),
    cooldown_minutes integer NOT NULL DEFAULT 60 CHECK (cooldown_minutes >= 0),
    is_active boolean NOT NULL DEFAULT true,
    expires_at timestamptz,
    last_triggered_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ix_alert_rules_match ON alert_rules(asset_id, expected_action, is_active);

CREATE TABLE alert_channels (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_rule_id uuid NOT NULL REFERENCES alert_rules(id) ON DELETE CASCADE,
    channel varchar(20) NOT NULL CHECK (channel IN ('push','email','websocket')),
    is_enabled boolean NOT NULL DEFAULT true,
    UNIQUE (alert_rule_id, channel)
);

CREATE TABLE market_signals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id uuid NOT NULL REFERENCES assets(id),
    source_service varchar(80) NOT NULL,
    source_event_id varchar(160) NOT NULL,
    action varchar(20) NOT NULL CHECK (action IN ('SAFE_BUY','TAKE_PROFIT','HOLD')),
    timeframe varchar(10) NOT NULL,
    confidence numeric(5,4) NOT NULL CHECK (confidence BETWEEN 0 AND 1),
    price numeric(38,18) NOT NULL CHECK (price >= 0),
    signal_time timestamptz NOT NULL,
    expires_at timestamptz,
    reasons jsonb NOT NULL DEFAULT '[]'::jsonb,
    indicators jsonb NOT NULL DEFAULT '{}'::jsonb,
    raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (source_service, source_event_id)
);

CREATE INDEX ix_market_signals_asset_time ON market_signals(asset_id, signal_time DESC);

CREATE TABLE alert_deliveries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_rule_id uuid NOT NULL REFERENCES alert_rules(id) ON DELETE CASCADE,
    signal_id uuid NOT NULL REFERENCES market_signals(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    dedupe_key varchar(200) NOT NULL UNIQUE,
    status varchar(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','sent','failed','cancelled')),
    created_at timestamptz NOT NULL DEFAULT now(),
    sent_at timestamptz,
    failure_reason text,
    UNIQUE (alert_rule_id, signal_id)
);

CREATE TABLE notification_outbox (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_delivery_id uuid NOT NULL REFERENCES alert_deliveries(id) ON DELETE CASCADE,
    event_type varchar(80) NOT NULL DEFAULT 'alert.created',
    payload jsonb NOT NULL,
    attempts integer NOT NULL DEFAULT 0,
    available_at timestamptz NOT NULL DEFAULT now(),
    processed_at timestamptz,
    last_error text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ix_outbox_pending ON notification_outbox(available_at) WHERE processed_at IS NULL;

CREATE TABLE user_devices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    platform varchar(20) NOT NULL CHECK (platform IN ('ios','android','web')),
    push_token text NOT NULL UNIQUE,
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE paper_accounts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    name varchar(100) NOT NULL,
    base_currency char(3) NOT NULL DEFAULT 'USD',
    cash_balance numeric(38,18) NOT NULL DEFAULT 100000 CHECK (cash_balance >= 0),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE paper_orders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id uuid NOT NULL REFERENCES paper_accounts(id) ON DELETE CASCADE,
    asset_id uuid NOT NULL REFERENCES assets(id),
    side varchar(4) NOT NULL CHECK (side IN ('buy','sell')),
    order_type varchar(10) NOT NULL CHECK (order_type IN ('market','limit')),
    quantity numeric(38,18) NOT NULL CHECK (quantity > 0),
    limit_price numeric(38,18),
    filled_price numeric(38,18),
    status varchar(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','filled','cancelled','rejected')),
    created_at timestamptz NOT NULL DEFAULT now(),
    filled_at timestamptz
);

CREATE TABLE paper_positions (
    account_id uuid NOT NULL REFERENCES paper_accounts(id) ON DELETE CASCADE,
    asset_id uuid NOT NULL REFERENCES assets(id),
    quantity numeric(38,18) NOT NULL DEFAULT 0,
    average_cost numeric(38,18) NOT NULL DEFAULT 0,
    realized_pnl numeric(38,18) NOT NULL DEFAULT 0,
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (account_id, asset_id)
);

COMMIT;
