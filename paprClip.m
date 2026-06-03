function y = paprClip(x, clipLevel_dB)

% RMS振幅を計算
rmsAmp = sqrt(mean(abs(x(:)).^2));

% RMS基準のクリッピングしきい値
A = rmsAmp * 10^(clipLevel_dB/20);

% 振幅と位相に分解
mag = abs(x);
ph = angle(x);

% クリッピング処理
y = x;
idx = mag > A;
y(idx) = A .* exp(1j*ph(idx));

end