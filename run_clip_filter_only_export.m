% run_clip_filter_only_export.m
%
% 前提：
% Workspaceに waveform, Fs が存在すること
%
% 出力：
% waveform_clip_filt_6
% waveform_clip_filt_7
% waveform_clip_filt_8
% waveform_clip_filt_9
% waveform_clip_filt_10
% waveform_clip_filt_11
% waveform_clip_filt_12
% waveform_clip_filt_13

%% ============================================================
%  1. 条件設定
% ============================================================

channelBW = 100e6;      % チャネル帯域幅 [Hz]

%% ============================================================
%  2. 6～13 dBでクリッピング + フィルタリング
% ============================================================

for clipLevel_dB = 6:13

    fprintf("\n============================================\n");
    fprintf("Clipping + Filtering: threshold = %d dB\n", clipLevel_dB);
    fprintf("============================================\n");

    %% 単純クリッピング
    x_clip = paprClip_local(waveform, clipLevel_dB);

    %% RMSを元波形に合わせる
    x_clip = normalizeRMS_local(x_clip, waveform);

    %% フィルタリング
    x_clip_filt = bandLimitAfterClip_local(x_clip, Fs, channelBW);

    %% RMSを元波形に合わせる
    x_clip_filt = normalizeRMS_local(x_clip_filt, waveform);

    %% PAPR表示
    papr_now = calcPAPR_local(x_clip_filt);
    fprintf("waveform_clip_filt_%d PAPR = %.2f dB\n", clipLevel_dB, papr_now);

    %% 指定名でWorkspace変数として作成
    varName = sprintf("waveform_clip_filt_%d", clipLevel_dB);
    assignin("base", varName, x_clip_filt);

end

%% ============================================================
%  3. 不要な一時変数を削除
% ============================================================

clear channelBW clipLevel_dB x_clip x_clip_filt papr_now varName

disp(" ");
disp("Generated variables:");
disp("waveform_clip_filt_6");
disp("waveform_clip_filt_7");
disp("waveform_clip_filt_8");
disp("waveform_clip_filt_9");
disp("waveform_clip_filt_10");
disp("waveform_clip_filt_11");
disp("waveform_clip_filt_12");
disp("waveform_clip_filt_13");


%% ============================================================
%  Local Functions
% ============================================================

function papr_dB = calcPAPR_local(x)

    p = abs(x).^2;
    papr_dB = 10*log10(max(p(:)) / mean(p(:)));

end


function y = normalizeRMS_local(x, ref)

    rmsX = sqrt(mean(abs(x(:)).^2));
    rmsRef = sqrt(mean(abs(ref(:)).^2));

    y = x / rmsX * rmsRef;

end


function y = paprClip_local(x, clipLevel_dB)

    rmsAmp = sqrt(mean(abs(x(:)).^2));
    A = rmsAmp * 10^(clipLevel_dB/20);

    mag = abs(x);
    ph = angle(x);

    y = x;
    idx = mag > A;

    y(idx) = A .* exp(1j*ph(idx));

end


function y = bandLimitAfterClip_local(x, Fs, channelBW)

    % 100 MHz波形ではフィルタ余裕が小さいため、少し広めに通す
    passbandEdge = 0.52 * channelBW;
    stopbandEdge = 0.60 * channelBW;

    nyq = Fs/2;

    if stopbandEdge >= 0.95 * nyq
        stopbandEdge = 0.95 * nyq;
    end

    if passbandEdge >= stopbandEdge
        passbandEdge = 0.85 * stopbandEdge;
    end

    Wp = passbandEdge / nyq;
    Ws = stopbandEdge / nyq;
    Wc = (Wp + Ws)/2;

    filtOrder = 300;
    b = fir1(filtOrder, Wc, "low");

    delay = filtOrder/2;

    y = zeros(size(x));

    for col = 1:size(x,2)

        xpad = [x(:,col); zeros(delay,1)];
        yf = filter(b, 1, xpad);

        y(:,col) = yf(delay+1:delay+size(x,1));

    end

end
