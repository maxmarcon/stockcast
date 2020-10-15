import {StockMetadata} from "@/utils/stockMetadata";
import {Prices} from "@/utils/prices";
import {Stock} from "@/utils/stock";

export interface StockBag {

  metadata: StockMetadata;
  prices: Prices;
  stock: Stock;
  variant?: string;
  label: string;
  tradingMode: boolean;
}
