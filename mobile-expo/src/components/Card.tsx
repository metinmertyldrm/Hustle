import { StyleSheet, View, type ViewProps } from 'react-native';
import { colors, layout } from '../theme/colors';

export function Card({ style, ...props }: ViewProps) { return <View style={[styles.card, style]} {...props} />; }
const styles = StyleSheet.create({ card: { backgroundColor: colors.surface, borderColor: colors.border, borderRadius: layout.radius, borderWidth: 1, padding: 18 } });
