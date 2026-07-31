import { Ionicons } from '@expo/vector-icons';
import { StyleSheet, Text, View } from 'react-native';
import { colors } from '../theme/colors';

export function BrandHeader() { return <View style={styles.row}><View style={styles.logo}><Ionicons name="trending-up" size={31} color={colors.black} /></View><View><Text style={styles.brand}>HUSTLE</Text><Text style={styles.tagline}>Akıllı piyasa sinyalleri</Text></View></View>; }
const styles = StyleSheet.create({ row: { flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 8 }, logo: { width: 52, height: 52, borderRadius: 15, backgroundColor: colors.primary, alignItems: 'center', justifyContent: 'center' }, brand: { color: colors.text, fontSize: 25, fontWeight: '900', letterSpacing: 2.5 }, tagline: { color: colors.muted, marginTop: 2 } });
