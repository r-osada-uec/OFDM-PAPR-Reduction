function papr_dB = calcPAPR(x)
    p = abs(x).^2;
    papr_dB = 10*log10(max(p(:)) / mean(p(:)));
end
