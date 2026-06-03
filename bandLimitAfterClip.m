function y = bandLimitAfterClip(x, fs, channelBW)

% bandLimitAfterClip
% クリッピング後のOFDM/5G NR波形に対して低域通過FIRフィルタを適用する
%
% x         : 入力複素IQ波形
% fs        : サンプルレート [Hz]
% channelBW : チャネル帯域幅 [Hz]
%
% y         : フィルタ後波形

% ===== フィルタ設計パラメータ =====

% 通過帯域端
% チャネル帯域の半分より少し広めに通す
passbandEdge = 0.50 * channelBW;

% 阻止帯域端
% 通過帯域より少し外側
stopbandEdge = 0.60 * channelBW;

% ナイキスト周波数
nyq = fs/2;

% 安全対策
if stopbandEdge >= nyq
    warning("stopbandEdge がナイキスト周波数を超えるため、0.95*Nyquistに制限します。");
    stopbandEdge = 0.95 * nyq;
end

if passbandEdge >= stopbandEdge
    passbandEdge = 0.85 * stopbandEdge;
end

% 正規化周波数
Wp = passbandEdge / nyq;
Ws = stopbandEdge / nyq;

% ===== FIRフィルタ設計 =====
% fir1ではカットオフを1つ指定するので、通過帯域と阻止帯域の中間を使う
Wc = (Wp + Ws)/2;

filtOrder = 300;
b = fir1(filtOrder, Wc, "low");

% ===== フィルタ適用 =====
% filtfiltを使うことで群遅延を避ける
y = zeros(size(x));

for col = 1:size(x,2)
    y(:,col) = filtfilt(b, 1, x(:,col));
end

end