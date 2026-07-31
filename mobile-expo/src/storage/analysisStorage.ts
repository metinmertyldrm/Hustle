import AsyncStorage from '@react-native-async-storage/async-storage';
import { parseAnalysis } from '../services/analysisApi';
import type { Analysis } from '../types/analysis';

const LAST_ANALYSIS_KEY = '@hustle/last-analysis';

export async function saveLastAnalysis(analysis: Analysis): Promise<void> {
  await AsyncStorage.setItem(LAST_ANALYSIS_KEY, JSON.stringify(analysis));
}

export async function loadLastAnalysis(): Promise<Analysis | null> {
  const raw = await AsyncStorage.getItem(LAST_ANALYSIS_KEY);
  if (!raw) return null;
  try { return parseAnalysis(JSON.parse(raw)); } catch { return null; }
}
