import BackendEnvelope from '@/utils/backend-envelope.ts'

export interface StockMetadata {
    symbol: string;
    name: string;
    currency: string;
    figi: string;
    isins: string[];
}

export type SearchResponse = BackendEnvelope<StockMetadata[]>

export type SymbolResponse = BackendEnvelope<StockMetadata>
