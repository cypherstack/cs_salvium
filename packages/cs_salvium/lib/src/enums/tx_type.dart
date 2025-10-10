enum TxType {
  Unset(0),
  Miner(1),
  Protocol(2),
  Transfer(3),
  Convert(4),
  Burn(5),
  Stake(6),
  Return(7),
  Audit(8);

  final int value;
  const TxType(this.value);

  String get displayName => switch (this) {
        TxType.Unset => 'Standard Transaction',
        TxType.Miner => 'Miner Reward',
        _ => "$name Transaction",
      };
}
