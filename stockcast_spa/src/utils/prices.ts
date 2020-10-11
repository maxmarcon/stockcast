import BackendEnvelope from '@/utils/backend-envelope.ts'

export interface HistoricalPrice {
    symbol: string;
    date: string | Date;
    open: string;
    high: string;
    low: string;
    close: string;
    volume: string;
    uOpen: string;
    uHigh: string;
    uLow: string;
    uClose: string;
    uVolume: string;
    change: string;
    changePercent: string;
    label: string;
    changeOverTime: string;
}

export interface Performance {
    baseline: number | null;
    relative: boolean;
    raw: number;
    trading: number;
    short_trading: number;
    strategy: Trading[];
}

export interface Trading {
    date: string | Date;
    price: string;
    action: 'sell' | 'buy';
}

export interface Prices {
    prices: HistoricalPrice[];
    performance: Performance;
}

export type PriceResponse = BackendEnvelope<Prices>
