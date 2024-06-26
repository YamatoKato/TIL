# zk-Rollup の仕組み

- 日付: 2024-04-29
- キーワード: Blockchain,ZKP,zk-Rollup,zkSync

## 概要

レイヤー 2 のスケーリングソリューションで、Ethereum をよりスケーラブルにするために、コントラクト計算とトランザクション実行をオフチェーンにするもの。

zkSync Era の場合、zkSync のトランザクションをまとめてハッシュ化するバッチ処理をし、そのハッシュ値と state の差分のみを Ethereum に保存する。そして、そのハッシュ値が正しいことを ZKP を用いて証明している。
ハッシュ値を Ethereum に保存したものの、まだこのハッシュ値が本当に rollup のトランザクションをまとめてハッシュ化したものかはわからないため、rollup のトランザクションをまとめたという情報を ZKP を活用して証明する。

### ロールアップとは

ブロックチェーンのロールアップは L2 ブロックチェーン（別のネットワーク）でトランザクションを処理し、トランザクションをバッチにロールアップして L1 に公開する。

ロールアップの大前提は、複数の手紙（トランザクション）　を封筒（バッチ）　にまとめ、投函（ブロックチェーンに記録）　すること。

以下 2 つのことを行うことで、イーサリアムネットワークの計算圧力を軽減します。

1. トランザクションを計算し、状態保存をオフチェーンに移動する。
2. イーサリアム上に保存されるすべてのトランザクションのデータを圧縮する。
   例えば、単純な ETH の転送はイーサリアム上で～ 110 バイトかかりますが、ロールアップでは約～ 12 バイトで済みます。

## 仕組み

コアインフラと実行プロセスの 2 つのプロセスに分けられる。

さらにコアインフラにはオンチェーン・コントラクトとオフチェーン仮想マシン（zkEVM）の 2 つの部分がある。

### 【コアインフラ】オンチェーン・コントラクト

ユーザーがトランザクションを送信するたびに、トランザクションのデータを受け取り、それを zkEVM に送信する。

1. メインコントラクト

   ロールアップブロックを保存し、預金を追跡し、zkRollup から来る状態更新を監視する。L2 から L1 に資産を引き出したりする際のゲートウェイとしても機能する。

2. 検証コントラクト

   L2 で行われたトランザクションのバッチが正しく ZKP を用いて処理されたという証明を L2 オペレーターから受け取り、その証明が正しいかどうかをここで検証することで、トランザクションの正確性と完全性を保証する。検証が成功すると、L1 上でトランザクションバッチが確定され、L2 の状態変更が L1 にコミットされる。

### 【コアインフラ】オフチェーン仮想マシン

トランザクションをまとめて処理してゼロ知識証明（ZKP）の生成を行い、その結果をイーサリアムの検証コントラクトに送信する。

### 実行プロセス

ZK ロールアップの実行プロセスは、シーケンシング、証明生成、証明検証の 3 つの部分に分けることができる。

① シーケンシング
イーサリアムのノードオペレータと同様に、L2 にはトランザクションを実行し、それをバッチにまとめ、ZK ロールアップコントラクトに提出するシーケンサがいます。

![](https://storage.googleapis.com/zenn-user-upload/04e3e8c91ab6-20230528.png)

このプロセスはシーケンシングと呼ばれます。

② 証明の生成
ZK rollup オペレータは、バッチされたトランザクションの正しさを検証するための有効性証明を作成します。

③ 証明の検証
検証メカニズム、すなわち zk SNARK または zk STARK は、オンチェーンで提出された zk プルーフの完全性を検証するために使用されます。

証明は、L1 のプレ・ステートルートから ZK ロールアップのポスト・ステートルートまでの有効なトランザクションのシーケンスを証明する必要があります。

    「pre-state root」 は、トランザクションが実行される前のブロックチェーンの状態を表します。
    「post-state root」 は、トランザクションが実行された後のブロックチェーンの状態を表します。
    証明のプロセスは、トランザクションが有効で、結果として得られたブロックチェーンの状態（post-state root）が正確であることを証明するものです。

この証明が有効であれば、ZK ロールアップの「post-state root」は「有効」と認定され、Ethereum に公開されます。

1. **トランザクションの受付と集約**

   - **ユーザー操作**: ユーザーは、zkSync プラットフォームを介してトランザクションを送信します。この操作は、ユーザーの EOA から行われ、イーサリアムのトランザクションを介して行われます。
   - **トランザクションの集約**: シーケンサーは、送信されたトランザクションを一定期間集め、一つの大きなバッチとしてまとめます。このバッチは、後にオペレーターによって処理されます。

2. **データの処理とハッシュ化**

   - **データの処理**: シーケンサーはバッチ内のトランザクションを処理し、それぞれのトランザクションの結果を計算します。
   - **ハッシュ化**: 処理されたトランザクションのデータから、一つのハッシュ値を生成します。このハッシュ値は、バッチ内の全トランザクションを代表するものです。

3. **ゼロ知識証明の生成**

   - **ZKP の生成**: オペレーターは、シーケンサーによって生成されたハッシュ値がバッチ内のトランザクションから正しく計算されたものであることを証明するために、ゼロ知識証明を作成します。

4. **証明とハッシュ値のイーサリアムへのコミット**

   - **証明の送信**: オペレーターは、生成したハッシュ値とゼロ知識証明をイーサリアムのメインチェーンに送信します。送信方法は、イーサリアムのトランザクションを介して行われます。
   - **イーサリアムでの検証**: イーサリアムのネットワークは、受け取ったゼロ知識証明を検証し、その正当性を確認します。証明が正しいと認められれば、ハッシュ値がメインチェーンに保存されます。イーサリアムのメインチェーン上の特定のスマートコントラクト（検証コントラクト）を利用して検証が行われます。

5. **ステートの更新**

   - **ステートの差分の適用**: ハッシュ値とともに、トランザクションによって変更されたステートの差分（state diff）もイーサリアムに保存されます。これにより、システムの全体的な状態が更新されます。このステートの更新は、メインコントラクトによって行われます。

6. **最終的な確認とユーザーへの反映**
   - **確認と反映**: 一連のプロセスが完了すると、トランザクションは最終的に確定され、その結果がユーザーの EOA に反映されます。

> **Q1**. オペレーターとシーケンサーを信じる必要があるのでは？

そうです。Matter Labs が開発を主導しており、初期段階ではオペレーターやシーケンサーの役割も同団体が担っている可能性が高いです。
zkSync では独自トークンの発行は行われておらず、運用の大部分が中央集権化されていますが、将来的にシーケンサーが分散化される可能性があり、その場合は独自トークンが必要となる可能性があるとされています。しかし、オンチェーンにて ZKP を用いて証明されるため、彼らが不正なトランザクションを生成しても、それが検知されることが保証されています。したがって、不正の余地がないとされているが、中央集権的であることには変わりない。

> **Q2**. L1 自身は、L2 に送られた複数の Tx の詳細を知らずにどうやってそれらの Tx を最終的に反映させるのか

L2 で実行された複数の Tx の結果が反映されたステート自体が L1 に反映される。このステートの更新は、メインコントラクトによって行われる。反映前と反映後のステートの差分には、例えば「A のアカウントから 0.0001ETH が減少し、B のアカウントに 0.0001ETH が加算された」という情報が含まれます。L1 では、この情報を基にステートを更新しますが、個々のトランザクションの詳細（誰がいつどのように送金したかなど）は含まれません。

> **Q3**. オンチェーンと L2 の通信方法は？

**A さんから B さんへの 0.00001ETH の送金の Tx 例**

A さんは、zkSync Era プラットフォーム（L2）を介して、B さんに 0.00001ETH を送金するトランザクションを生成します。この操作は、A さんの EOA から行われます。トランザクションは、A さんの秘密鍵で署名され、zkSync のネットワークに送信されます。

**生成したハッシュ値とゼロ知識証明の送信**

スマートコントラクトとブロックチェーンのインタラクションを通じて行われます。具体的には、zkSync（L2）からイーサリアム（L1）へのデータ転送は、特定のスマートコントラクト機能を使用して実行されます。

1. メッセージの生成（L2）:
   L2 で複数のトランザクションをまとめたトランザクションが生成され、これにより特定のメッセージが作成されます。このメッセージは、通常、トランザクションのデータや状態の変更を含みます。

2. メッセージの L1 への送信:
   生成されたメッセージは、zkSync のスマートコントラクトを通じて L1 に送信されます。このステップでは、メッセージは L1 のスマートコントラクト（通常は「Mailbox」や「L1Messenger」などと呼ばれる）によって受け取られ、処理されます

3. L1 でのメッセージの処理:
   L1 のスマートコントラクトは、受け取ったメッセージを検証し、必要に応じて L1 の状態を更新します。このプロセスには、ゼロ知識証明（ZKP）の検証が含まれることがあり、これにより L2 でのトランザクションの正確性が保証されます

[source](https://docs.zksync.io/build/tutorials/how-to/send-message-l2-l1.html)

> **Q4**. シーケンサーとオペレーターの関係

シーケンサーはトランザクションの受付と初期処理を担い、オペレーターはそれらのデータを基にゼロ知識証明を生成し、イーサリアムメインチェーンにコミットする役割を果たしている。

> **Q5**. Trusted Setup はどこで誰が行なっているのか

Trusted Setup はセットアップパーティとして事前に行われます。そのセットアッププロセスが複数の独立した参加者によって行われ、その中の少なくとも一人が正直に行動することが保証されている場合、全体のセットアップの安全性が確保されます。セットアッププロセスは公開され、透明性が保たれていて、外部の専門家やコミュニティメンバーがプロセスを監視し、検証することが可能です。

[source](https://a16zcrypto.com/posts/article/on-chain-trusted-setup-ceremony/)

## 利点と特徴

### ハイパースケーラビリティ

- スループットの強化:

  zkSync は、イーサリアムのトランザクション容量を 14 トランザクション/秒 (TPS) から 2000 TPS 以上に増幅します。
  zk-Rollup テクノロジー: zk-rollup を利用して複数のトランザクションを 1 つのバッチに集約し、複数のトランザクションの同時検証を可能にし、処理を大幅に高速化します。

### 低コストの取引

通常のイーサリアムメインネットでは、トランザクション手数料が数十ドルになることがありますが、zkSync を利用すると、その手数料は 1 ドル以下に抑えることが可能です。

- オフメインネット処理

  トランザクションはメインのイーサリアムネットワークから離れて処理され、検証のためにバッチ処理されるため、個別のガス支払いの必要性が軽減されます。

- 手頃な価格

  このバッチ方式により、従来のオンチェーン トランザクションと比較してトランザクション コストが大幅に低くなり、zkSync はガス料金が高いために以前は実現できなかったマイクロトランザクションに最適です。

### ネットワークの混雑を軽減する

- オフチェーン処理

  オフチェーンでトランザクションを処理することにより、zkSync はイーサリアムのネットワークへの負担を効果的に軽減します。

- 確認の迅速化: これにより、トランザクションの確認が迅速化され、特にネットワーク需要が高い期間におけるユーザー エクスペリエンスと効率が向上します。

### 安全でトラストレスなトランザクション

- ゼロ知識証明システム

  zkSync は、ZK 証明を使用して機密データを明らかにすることなくトランザクションを検証し、プライバシーとセキュリティを確保します。

- 脅威に対する回復力

  この方法は潜在的なセキュリティ脅威から保護し、トランザクションに安全でトラストレスな環境を提供します。

要約すると、zkSync はイーサリアムのスケーラビリティ、コスト効率、輻輳管理、セキュリティに対する革新的なアプローチを導入し、イーサリアムをブロックチェーン技術と暗号通貨トランザクションを進歩させるための重要なソリューションとして位置づけています。

### Optimistic Rollup よりも引き出し期間が短い

従来の Optimistic Rollup 系ソリューションでは、引き出しに 1 週間ほどかかることがありましたが、zkSync を利用することで、引き出しに必要な期間が数時間程度に短縮されます。

- 資産の流動性が向上

  短い期間で資産を引き出せることで、ユーザーは自分の資産をより柔軟に管理できます。

- リスクの低減

  引き出しにかかる時間が短いことで、市場の変動やネットワークの混雑によるリスクが軽減されます。

> **Q6**. zk-Rollup vs AccountAbstraction

**目的**

- zk-Rollup は、トランザクションの処理速度とスループットを大幅に向上させること
- Account Abstraction は、秘密鍵を持たないアカウントがトランザクションを送信できるようにすることで、ユーザーエクスペリエンスを向上させる

**共通点**

- どちらもエンドユーザーの体験を向上させている

> **Q7**. 集約署名 vs zk-Rollup

- 集約署名は複数の署名を一つにまとめることで、検証の効率化とデータ節約を目的としています。

- zk-Rollup は情報を開示することなくその情報の正当性を証明することを目的としています。

したがって、L2 で Rollup を行うという点でいうと、集約署名自体には、トランザクションの内容を秘匿する機能はなく、zk-Rollup は、トランザクションの内容を秘匿しつつ、その正確性を保証する強力なツールであるといえます。

## 結論と展望

### 結論

- zkRollup は、ゼロ知識証明を利用してイーサリアムを拡張する手法
  - 高いコストの問題を解決する（手数料はイーサリアムの 1/10 になる）
  - トランザクションの実行速度を向上させる（イーサリアムの 20 倍以上になる）
    - イーサリアムの The surge アップグレードにより、さらに速度が向上する可能
  - 安全性はイーサリアムと同等
- ゼロ知識証明は、ブロックチェーンの発展において重要な技術である
  - ブロックチェーンのコストやプライバシーの問題を解決する

### 展望

1. Proof の生成コストの改善 1

   - ハードウェアの進化（GPU など）
   - 暗号理論の進歩によって Proof の生成コストが改善される 2.イーサリアムの

2. The Surge アップグレード

   - L1 ブロックで取り込めるデータが増えるため、TPS がさらに向上する可能性がある

3. EVM との互換性の向上
   - kRollup のエコシステムがより活発になることが期待される

## 課題

- Trusted Setup が必要

  zkSync は、zk-Rollup の一種であり、zk-SNARKs を使用しています。zk-SNARKs の生成には、信頼できるセットアップフェーズが必要になります。このフェーズでは、複数人のセットアップパーティーが、チェーン側と Layer2 側の共通の参照点となる証明の生成と検証に必要なパラメータ(共通の参照文字列)とそれの生成に必要な暗号学的に重要な秘密な情報を生成します。もしセットアップが不正に行われた場合には、システムのセキュリティが損なわれるため、セットアップの完了後に安全に破棄される必要があります。

- 中央集権化のリスク

  zkSync は、オペレーターがトランザクションを集約し、イーサリアムにコミットすることで機能します。オペレーターが悪意を持ってシステムを操作することで、ユーザーの資産が危険にさらされる可能性があります。このリスクを軽減するためには、適切な監視とセキュリティ対策が必要です。
