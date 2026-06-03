% run_papr_clipping.m
% 前提：
% 5G Waveform GeneratorからExport to Workspace済み
% Workspace内に waveform, Fs, cfgDL が存在すること
%
% waveform : 5G NR複素IQ波形
% Fs       : サンプルレート [Hz]
% cfgDL    : 5G NR Downlink構成

%% 1. 条件設定
clipLevel_dB = 8;

% チャネル帯域幅 [Hz]
channelBW = 100e6;

% ICF反復回数
numIter = 3;

%% 2. 元波形のPAPR計算
papr_org = calcPAPR(waveform);
fprintf("Original PAPR = %.2f dB\n", papr_org);

%% 3. 単純クリッピング
waveform_clip = paprClip(waveform, clipLevel_dB);

% RMS電力を元波形とそろえる
waveform_clip = waveform_clip / rms(waveform_clip(:)) * rms(waveform(:));

papr_clip = calcPAPR(waveform_clip);
fprintf("Hard clipped PAPR = %.2f dB\n", papr_clip);

%% 4. クリッピング後フィルタリング 1回
waveform_clip_filt = bandLimitAfterClip(waveform_clip, Fs, channelBW);

% RMS電力を元波形とそろえる
waveform_clip_filt = waveform_clip_filt / rms(waveform_clip_filt(:)) * rms(waveform(:));

papr_clip_filt = calcPAPR(waveform_clip_filt);
fprintf("Clipped + filtered PAPR = %.2f dB\n", papr_clip_filt);

%% 5. ICF: クリッピング＋フィルタリング反復
[waveform_icf, papr_icf_history] = iterativeClipFilter( ...
    waveform, Fs, channelBW, clipLevel_dB, numIter);

papr_icf = calcPAPR(waveform_icf);
fprintf("ICF final PAPR = %.2f dB\n", papr_icf);

%% 6. Analyzer用構造体：元波形
waveform_org_for_analyzer = struct();
waveform_org_for_analyzer.waveform = waveform;
waveform_org_for_analyzer.fs = Fs;
waveform_org_for_analyzer.configuration = cfgDL;

%% 7. Analyzer用構造体：単純クリッピング波形
waveform_clip_for_analyzer = struct();
waveform_clip_for_analyzer.waveform = waveform_clip;
waveform_clip_for_analyzer.fs = Fs;
waveform_clip_for_analyzer.configuration = cfgDL;

%% 8. Analyzer用構造体：クリッピング＋フィルタリング1回
waveform_clip_filt_for_analyzer = struct();
waveform_clip_filt_for_analyzer.waveform = waveform_clip_filt;
waveform_clip_filt_for_analyzer.fs = Fs;
waveform_clip_filt_for_analyzer.configuration = cfgDL;

%% 9. Analyzer用構造体：ICF後波形
waveform_icf_for_analyzer = struct();
waveform_icf_for_analyzer.waveform = waveform_icf;
waveform_icf_for_analyzer.fs = Fs;
waveform_icf_for_analyzer.configuration = cfgDL;

%% 10. 結果表示
disp("Analyzer用構造体を作成しました。");
disp("Import from Workspaceで以下を選択してください。");
disp("1. waveform_org_for_analyzer");
disp("2. waveform_clip_for_analyzer");
disp("3. waveform_clip_filt_for_analyzer");
disp("4. waveform_icf_for_analyzer");

%% 11. 確認
disp("---- Variable check ----");
fprintf("Fs = %.3f MHz\n", Fs/1e6);
fprintf("clipLevel_dB = %.1f dB\n", clipLevel_dB);
fprintf("channelBW = %.3f MHz\n", channelBW/1e6);
fprintf("numIter = %d\n", numIter);

%% 12. PAPR履歴プロット
figure;
plot(0:numIter, papr_icf_history, "-o");
grid on;
xlabel("Iteration number");
ylabel("PAPR [dB]");
title("PAPR history of iterative clipping and filtering");
