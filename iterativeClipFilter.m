function [y, paprHistory] = iterativeClipFilter(x, Fs, channelBW, clipLevel_dB, numIter)

% iterativeClipFilter
% クリッピングとフィルタリングを反復するICF処理
%
% x            : 入力複素IQ波形
% Fs           : サンプルレート [Hz]
% channelBW    : チャネル帯域幅 [Hz]
% clipLevel_dB : RMS基準クリッピングレベル [dB]
% numIter      : 反復回数
%
% y            : ICF後の波形
% paprHistory  : 各段階のPAPR履歴 [dB]
%
% paprHistory(1)      : 元波形
% paprHistory(k+1)    : k回目のclip+filter後

% 初期化
y = x;

% 元波形のRMS電力を基準として保存
rmsRef = rms(x(:));

% PAPR履歴
paprHistory = zeros(numIter+1,1);
paprHistory(1) = calcPAPR(y);

fprintf("ICF start\n");
fprintf("Original PAPR = %.2f dB\n", paprHistory(1));

for k = 1:numIter

    % ===== 1. クリッピング =====
    y = paprClip(y, clipLevel_dB);

    % ===== 2. フィルタリング =====
    y = bandLimitAfterClip(y, Fs, channelBW);

    % ===== 3. RMS電力を元波形にそろえる =====
    y = y / rms(y(:)) * rmsRef;

    % ===== 4. PAPR記録 =====
    paprHistory(k+1) = calcPAPR(y);

    fprintf("Iteration %d: PAPR = %.2f dB\n", k, paprHistory(k+1));

end

end