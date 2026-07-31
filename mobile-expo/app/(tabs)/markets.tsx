import { Ionicons } from '@expo/vector-icons';
import { StyleSheet, Text, View } from 'react-native';
import { Card } from '../../src/components/Card';
import { Screen, SectionHeader } from '../../src/components/Screen';
import { colors } from '../../src/theme/colors';
const symbols = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'BNBUSDT'];
export default function MarketsScreen() { return <Screen><SectionHeader title="Piyasalar" subtitle="Hızlı piyasa erişimi" />{symbols.map((symbol, index) => <Card key={symbol} style={styles.row}><View style={styles.icon}><Text style={styles.iconText}>{['₿', 'Ξ', 'S', 'B'][index]}</Text></View><View style={styles.content}><Text style={styles.symbol}>{symbol}</Text><Text style={styles.subtitle}>BINANCE • 7/24</Text></View><Ionicons name="chevron-forward" size={20} color={colors.muted} /></Card>)}</Screen>; }
const styles = StyleSheet.create({ row: { flexDirection: 'row', alignItems: 'center' }, icon: { width: 42, height: 42, borderRadius: 13, backgroundColor: colors.primaryDark, alignItems: 'center', justifyContent: 'center' }, iconText: { color: colors.primary, fontSize: 20, fontWeight: '800' }, content: { flex: 1, marginLeft: 13 }, symbol: { color: colors.text, fontWeight: '800', fontSize: 16 }, subtitle: { color: colors.muted, marginTop: 3, fontSize: 12 } });
