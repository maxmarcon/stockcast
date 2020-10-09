import {StockMetadata} from "@/utils/stockMetadata";
import {Prices} from "@/utils/prices";
import {Stock} from "@/utils/stock";

export interface StockData {

  metadata: StockMetadata;
  prices: Prices;
  stock: Stock;
}
