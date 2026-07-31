import { DarkTheme, ThemeProvider } from '@react-navigation/native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AnalysisProvider } from '../src/features/analysis/AnalysisContext';
import { WatchlistProvider } from '../src/features/watchlist/WatchlistContext';
import { colors } from '../src/theme/colors';

const hustleTheme = { ...DarkTheme, colors: { ...DarkTheme.colors, primary: colors.primary, background: colors.background, card: colors.surface, text: colors.text, border: colors.border } };
export default function RootLayout() { return <SafeAreaProvider><ThemeProvider value={hustleTheme}><AnalysisProvider><WatchlistProvider><Stack screenOptions={{ headerShown: false }}><Stack.Screen name="(tabs)" /></Stack></WatchlistProvider></AnalysisProvider><StatusBar style="light" /></ThemeProvider></SafeAreaProvider>; }
