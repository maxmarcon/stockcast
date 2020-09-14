export interface Symbol {
    symbol: string;
    name: string;
    currency: string;
    figi: string;
    isins: string[];
}

export interface SearchResponse {
    data: Symbol[]
}
