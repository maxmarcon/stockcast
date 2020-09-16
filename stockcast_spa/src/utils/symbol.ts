import BackendEnvelope from '@/utils/backend-envelope.ts';

export interface Symbol {
    symbol: string
    name: string
    currency: string
    figi: string
    isins: string[]
}

export type SearchResponse = BackendEnvelope<Symbol[]>

export type SymbolResponse = BackendEnvelope<Symbol>