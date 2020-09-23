import BackendEnvelope from '@/utils/backend-envelope.ts'

export interface RawStockData {
    symbol: string;
    name: string;
    currency: string;
    figi: string;
    isins: string[];
}

export type SearchResponse = BackendEnvelope<symbol[]>

export type SymbolResponse = BackendEnvelope<symbol>
