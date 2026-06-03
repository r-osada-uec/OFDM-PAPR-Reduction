# OFDM-PAPR-Reduction

5G NR OFDM信号に対するPAPR（Peak-to-Average Power Ratio）低減手法を検討するための MATLAB コード群です。  
本リポジトリでは、**`Re_SGwaveform.m` で基準となる 5G NR 波形を生成**し、  
**その他のスクリプトでクリッピング・フィルタリング・各種波形加工**を行います。

---

## 1. 概要

OFDM信号は高いPAPRを持つため、送信系の非線形歪みや出力バックオフの増大を招きます。  
本リポジトリでは、5G NR信号を対象として以下を行います。

- 5G NR OFDM波形の生成
- PAPRの計算
- クリッピングによるピーク低減
- クリッピング後のフィルタリング
- 条件ごとの波形出力
- MATLAB / 実機評価用データの作成

---

## 2. 動作環境

以下の環境を想定しています。

- MATLAB
- 5G Toolbox
- Signal Processing Toolbox（フィルタ処理で使用する場合）

---

## 3. 基本的な実行手順

本リポジトリでは、**最初に `Re_SGwaveform.m` を実行して基準波形を生成し、その後に各種スクリプトで波形加工を行う**流れを前提としています。

大まかな流れは以下の通りです。

1. `Re_SGwaveform.m` を実行して 5G NR 波形を生成
2. PAPR低減スクリプトを実行
3. 加工後波形を比較・保存・外部機器評価に使用

---

## 4. 5G NR波形の生成

最初に、基準となる 5G NR 波形を生成します。

```matlab
Re_SGwaveform
```
このスクリプトでは、以後の処理で使用する基準波形を作成します。
実行後、Workspace に少なくとも以下の変数があることを想定しています。

waveform : 元の複素 IQ 波形
Fs : サンプルレート [Hz]
cfgDL : 5G NR Downlink 設定（必要に応じて）

実行後は、以下で確認してください。
```matlab
whos waveform Fs cfgDL
```

生成した波形は nr5GWaveformAnalyzer で確認します。


## 5. 目的
本コードは、以下のような目的で使用することを想定しています。

OFDM信号のPAPR低減手法の基礎検討
5G NR波形に対するクリッピング影響の確認


## 6. 備考

スクリプトや関数の内容は、研究の進行に応じて更新される場合があります。


Author
r-osada-uec
