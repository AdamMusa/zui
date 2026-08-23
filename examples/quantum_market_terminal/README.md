# Quantum Market

A multi-asset paper-trading terminal written entirely in Ruby. Live deterministic ticks update
prices, candles, portfolio value, and unrealized P&L. Quantity, Buy, Sell, and confirmation controls
execute against simulated cash and positions, recalculate average cost, track realized P&L, reject
invalid orders, and expose the latest fill. It also exercises candlestick charts, reactive tables,
watchlists, allocation, risk, histograms, dialogs, and the framework legend adapter. All prices are
demo data.

```bash
zui run main.rb
```
