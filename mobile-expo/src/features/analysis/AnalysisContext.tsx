import { createContext, useCallback, useContext, useEffect, useMemo, useState, type PropsWithChildren } from 'react';
import { fetchAnalysis } from '../../services/analysisApi';
import { loadLastAnalysis, saveLastAnalysis } from '../../storage/analysisStorage';
import type { AnalysisState } from '../../types/analysis';

type AnalysisContextValue = AnalysisState & { analyze: (symbol: string, interval: string) => Promise<void> };
const AnalysisContext = createContext<AnalysisContextValue | null>(null);

export function AnalysisProvider({ children }: PropsWithChildren) {
  const [state, setState] = useState<AnalysisState>({ status: 'idle', data: null });
  useEffect(() => { void loadLastAnalysis().then((data) => setState({ status: 'idle', data })); }, []);
  const analyze = useCallback(async (symbol: string, interval: string) => {
    setState((current) => ({ status: 'loading', data: current.data }));
    try {
      const data = await fetchAnalysis(symbol, interval);
      setState({ status: 'success', data });
      await saveLastAnalysis(data);
    } catch (error) {
      setState((current) => ({ status: 'error', data: current.data, message: error instanceof Error ? error.message : 'Analiz servisi isteği tamamlayamadı.' }));
    }
  }, []);
  const value = useMemo(() => ({ ...state, analyze }), [state, analyze]);
  return <AnalysisContext.Provider value={value}>{children}</AnalysisContext.Provider>;
}

export function useAnalysis(): AnalysisContextValue {
  const context = useContext(AnalysisContext);
  if (!context) throw new Error('useAnalysis, AnalysisProvider içinde kullanılmalıdır.');
  return context;
}
