% run_all_cfr_methods.m
%
% 前提：
% Workspaceに waveform, Fs が存在すること
%
% waveform : 元の5G NR複素IQ波形
% Fs       : サンプルレート [Hz]
%
% 出力：
% waveform_org       : 元波形
% waveform_clip      : 単純クリッピング後
% waveform_clip_filt : クリッピング + フィルタリング後
% waveform_icf       : Iterative Clipping and Filtering後
% waveform_pc        : Peak Cancellation後

%% ============================================================
%  1. 条件設定
% ============================================================

clipLevel_dB = 8;       % RMS基準CFしきい値 [dB]
channelBW = 100e6;      % チャネル帯域幅 [Hz]

numIterICF = 3;         % ICF反復回数
numIterPC  = 3;         % Peak Cancellation反復回数

% 100 MHz, SCS 120 kHz, 66 RBの実占有帯域
pulseBW = 95.04e6;      % Peak Cancellation用sincパルス帯域幅 [Hz]

%% ============================================================
%  2. Original
% ============================================================

waveform_org = waveform;

papr_org = calcPAPR_local(waveform_org);
fprintf("Original PAPR = %.2f dB\n", papr_org);

%% ============================================================
%  3. Hard Clipping
% ============================================================

waveform_clip = paprClip_local(waveform_org, clipLevel_dB);

% RMSを元波形に合わせる
waveform_clip = normalizeRMS_local(waveform_clip, waveform_org);

papr_clip = calcPAPR_local(waveform_clip);
fprintf("Hard Clipping PAPR = %.2f dB\n", papr_clip);

%% ============================================================
%  4. Clipping + Filtering
% ============================================================

waveform_clip_filt = bandLimitAfterClip_local(waveform_clip, Fs, channelBW);

% RMSを元波形に合わせる
waveform_clip_filt = normalizeRMS_local(waveform_clip_filt, waveform_org);

papr_clip_filt = calcPAPR_local(waveform_clip_filt);
fprintf("Clipping + Filtering PAPR = %.2f dB\n", papr_clip_filt);

%% ============================================================
%  5. ICF: Iterative Clipping and Filtering
% ============================================================

waveform_icf = iterativeClipFilter_local( ...
    waveform_org, Fs, channelBW, clipLevel_dB, numIterICF);

waveform_icf = normalizeRMS_local(waveform_icf, waveform_org);

papr_icf = calcPAPR_local(waveform_icf);
fprintf("ICF PAPR = %.2f dB\n", papr_icf);

%% ============================================================
%  6. Peak Cancellation
% ============================================================

waveform_pc = peakCancelCFR_CF_local( ...
    waveform_org, Fs, pulseBW, clipLevel_dB, numIterPC);

waveform_pc = normalizeRMS_local(waveform_pc, waveform_org);

papr_pc = calcPAPR_local(waveform_pc);
fprintf("Peak Cancellation PAPR = %.2f dB\n", papr_pc);

%% ============================================================
%  7. 結果表示
% ============================================================

disp(" ");
disp("===== Generated waveforms =====");
disp("waveform_org");
disp("waveform_clip");
disp("waveform_clip_filt");
disp("waveform_icf");
disp("waveform_pc");

disp(" ");
disp("===== PAPR summary =====");
fprintf("Original              : %.2f dB\n", papr_org);
fprintf("Hard Clipping          : %.2f dB\n", papr_clip);
fprintf("Clipping + Filtering   : %.2f dB\n", papr_clip_filt);
fprintf("ICF                    : %.2f dB\n", papr_icf);
fprintf("Peak Cancellation      : %.2f dB\n", papr_pc);

%% 必要なら、一時変数を消したい場合は以下を有効化
% clearvars -except waveform_org waveform_clip waveform_clip_filt waveform_icf waveform_pc Fs cfgDL


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


function y = iterativeClipFilter_local(x, Fs, channelBW, clipLevel_dB, numIter)

    y = x;
    rmsRef = sqrt(mean(abs(x(:)).^2));

    fprintf(" ");
    fprintf("ICF start\n");

    for k = 1:numIter

        y = paprClip_local(y, clipLevel_dB);
        y = bandLimitAfterClip_local(y, Fs, channelBW);

        rmsY = sqrt(mean(abs(y(:)).^2));
        y = y / rmsY * rmsRef;

        paprNow = calcPAPR_local(y);
        fprintf("ICF iteration %d: PAPR = %.2f dB\n", k, paprNow);

    end

end


function y = peakCancelCFR_CF_local(x, Fs, pulseBW, clipLevel_dB, numIter)

    y = x;

    rmsRef = sqrt(mean(abs(x(:)).^2));
    threshold = rmsRef * 10^(clipLevel_dB/20);

    % ===== PCの強さを弱めるための設定 =====
    cancelGain = 1;        % 超過分の100%だけキャンセル
    maxPeaksPerIter = 10000;    % 1反復あたり最大ピーク数
    minPeakSpacing = 1;     % ピーク間引き間隔 [samples]

    pulse = makeBlackmanSincPulse_local(Fs, pulseBW);

    L = length(pulse);
    halfL = floor(L/2);

    fprintf(" ");
    fprintf("Peak Cancellation start\n");
    fprintf("Threshold = RMS + %.2f dB\n", clipLevel_dB);
    fprintf("cancelGain = %.2f\n", cancelGain);
    fprintf("maxPeaksPerIter = %d\n", maxPeaksPerIter);

    for it = 1:numIter

        totalPeaks = 0;
        cancelSig = zeros(size(y));

        for col = 1:size(y,2)

            yc = y(:,col);

            mag = abs(yc);
            ph  = angle(yc);

            % しきい値超え
            peakIdx = find(mag > threshold);

            % 局所最大だけ
            peakIdx = selectLocalPeaks_local(mag, peakIdx);

            if isempty(peakIdx)
                continue;
            end

            % ピークの大きい順に並べる
            [~, sortIdx] = sort(mag(peakIdx), "descend");
            peakIdx = peakIdx(sortIdx);

            % 近すぎるピークを間引く
            peakIdx = thinPeaks_local(peakIdx, minPeakSpacing);

            % 最大数に制限
            if length(peakIdx) > maxPeaksPerIter
                peakIdx = peakIdx(1:maxPeaksPerIter);
            end

            totalPeaks = totalPeaks + length(peakIdx);

            for k = 1:length(peakIdx)

                n0 = peakIdx(k);

                excess = mag(n0) - threshold;

                if excess <= 0
                    continue;
                end

                % 超過分を全量ではなく一部だけキャンセル
                c = cancelGain * excess * exp(1j*ph(n0));

                nStart = n0 - halfL;
                nEnd   = n0 + halfL;

                pStart = 1;
                pEnd   = L;

                if nStart < 1
                    pStart = 2 - nStart;
                    nStart = 1;
                end

                if nEnd > size(y,1)
                    pEnd = L - (nEnd - size(y,1));
                    nEnd = size(y,1);
                end

                cancelSig(nStart:nEnd,col) = cancelSig(nStart:nEnd,col) + ...
                    c .* pulse(pStart:pEnd);

            end

        end

        y = y - cancelSig;

        % RMSを元に戻す
        rmsY = sqrt(mean(abs(y(:)).^2));
        y = y / rmsY * rmsRef;

        paprNow = calcPAPR_local(y);

        fprintf("Peak Cancellation iteration %d: peaks = %d, PAPR = %.2f dB\n", ...
            it, totalPeaks, paprNow);

    end

end


function pulse = makeBlackmanSincPulse_local(Fs, pulseBW)

    pulseLength = 129;

    n = -(pulseLength-1)/2 : (pulseLength-1)/2;

    fc = pulseBW/2;

    h = 2*fc/Fs * sinc(2*fc/Fs * n);

    w = blackman(pulseLength).';

    pulse = h .* w;

    pulse = pulse / max(abs(pulse));

    pulse = pulse(:);

end


function peakIdxOut = selectLocalPeaks_local(mag, peakIdxIn)

    magVec = mag(:);

    peakIdxOut = [];

    for k = 1:length(peakIdxIn)

        idx = peakIdxIn(k);

        if idx <= 1 || idx >= length(magVec)
            continue;
        end

        if magVec(idx) >= magVec(idx-1) && magVec(idx) >= magVec(idx+1)
            peakIdxOut(end+1,1) = idx;
        end

    end

end


function peakIdxOut = thinPeaks_local(peakIdxIn, minSpacing)

peakIdxOut = [];

for k = 1:length(peakIdxIn)

    idx = peakIdxIn(k);

    if isempty(peakIdxOut)
        peakIdxOut(end+1,1) = idx;
    else
        if all(abs(idx - peakIdxOut) >= minSpacing)
            peakIdxOut(end+1,1) = idx;
        end
    end

end

end