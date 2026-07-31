const configuredUrl = process.env.EXPO_PUBLIC_API_BASE_URL?.trim();

// Emülatör için uygun varsayılan. Fiziksel cihazlarda bilgisayarın LAN IP'si .env ile verilmelidir.
export const API_BASE_URL = (configuredUrl || 'http://10.0.2.2:8000').replace(/\/+$/, '');
