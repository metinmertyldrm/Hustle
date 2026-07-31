import type { PropsWithChildren } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors, layout } from '../theme/colors';

export function Screen({ children }: PropsWithChildren) { return <SafeAreaView edges={['top']} style={styles.safe}><ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">{children}</ScrollView></SafeAreaView>; }
export function SectionHeader({ title, subtitle }: { title: string; subtitle?: string }) { return <View style={styles.header}><Text style={styles.title}>{title}</Text>{subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}</View>; }
const styles = StyleSheet.create({ safe: { flex: 1, backgroundColor: colors.background }, content: { width: '100%', maxWidth: 720, alignSelf: 'center', padding: layout.gutter, paddingBottom: 36, gap: 14 }, header: { gap: 4, marginBottom: 4 }, title: { color: colors.text, fontSize: 26, fontWeight: '800' }, subtitle: { color: colors.muted, fontSize: 15, lineHeight: 22 } });
