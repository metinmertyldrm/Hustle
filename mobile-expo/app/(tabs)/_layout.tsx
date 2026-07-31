import { Ionicons } from '@expo/vector-icons';
import { Tabs } from 'expo-router';
import { colors } from '../../src/theme/colors';

const icons = { index: ['home-outline', 'home'], markets: ['stats-chart-outline', 'stats-chart'], watchlist: ['star-outline', 'star'], profile: ['person-outline', 'person'] } as const;
export default function TabLayout() { return <Tabs screenOptions={({ route }) => ({ headerShown: false, tabBarActiveTintColor: colors.primary, tabBarInactiveTintColor: colors.muted, tabBarStyle: { backgroundColor: colors.surface, borderTopColor: colors.border, height: 66, paddingTop: 7, paddingBottom: 7 }, tabBarLabelStyle: { fontSize: 11, fontWeight: '600' }, tabBarIcon: ({ color, size, focused }) => { const pair = icons[route.name as keyof typeof icons] ?? icons.index; return <Ionicons name={pair[focused ? 1 : 0]} size={size} color={color} />; } })}><Tabs.Screen name="index" options={{ title: 'Ana Sayfa' }} /><Tabs.Screen name="markets" options={{ title: 'Piyasalar' }} /><Tabs.Screen name="watchlist" options={{ title: 'Takip Listesi' }} /><Tabs.Screen name="profile" options={{ title: 'Profil' }} /></Tabs>; }
