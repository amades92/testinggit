N = 1e4;

x = randn(1,N);

Xfft = abs(fft(x));

figure;
subplot 211;plot(x);