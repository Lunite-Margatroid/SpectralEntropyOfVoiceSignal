clear
%% 读取
[x, fs] = audioread("audio1.wav");

%% 分帧
len_win = fs / 40;                  % 窗宽    25ms
len_frame = len_win;                % 帧长    25ms
len_inc = floor(len_frame * 0.8);   % 帧移    20ms
win = hamming(len_win);             % 海明窗
x_frame = enframe(x, win, len_inc); % 分帧

%% 编写熵谱公式
% 傅里叶变换
x_frame_freq = zeros(length(x_frame(:,1)), len_frame);
for index = 1:length(x_frame(:,1))
    x_frame_freq(index, :) = fft(x_frame(index, :));
end
% 短时功率谱
x_frame_pow = zeros(length(x_frame(:, 1)), 1);
for index = 1:length(x_frame_pow)
    temp = abs(x_frame_freq(index, :));
    temp = temp.^2;
    % temp = log(temp);
    x_frame_pow(index) = sum(temp) / length(temp); 
end
% Spectral entropy
x_spectralEntropy = zeros(length(x_frame(:, 1)), 1);
for index = 1:length(x_frame(:, 1))
    temp = abs(x_frame_freq(index, :));	% 频谱取模
    temp = temp.^2;						% 平方 能量
    if sum(temp) ~= 0
        x_pow_p = temp / sum(temp);		% 计算能量分布
        for jndex = 1:length(x_pow_p)	% 代入信息熵公式
            x_spectralEntropy(index) = x_spectralEntropy(index)-x_pow_p(jndex) * log(x_pow_p(jndex));
        end
    end
end
%% 用内建函数计算熵谱 
% Spectral entropy with build-in func
x_spectralEntropy0 = spectralEntropy(x ,fs, ...
    Window = win, OverlapLength = len_frame-len_inc, ...
    Range = [62.5, 5000]);      % 只要62.5Hz - 5000Hz的声音

% 是否平缓化熵谱
if false
    average_filter = ones(5, 1) / 5;
    x_spectralEntropy1 = conv(x_spectralEntropy0,average_filter);
    x_spectralEntropy2 = x_spectralEntropy1(3:(length(x_spectralEntropy1)-2));
else
    x_spectralEntropy2 = x_spectralEntropy0;
end

%%
gate = 0.7 * max(x_spectralEntropy2);           % 门限
x_SE_minus_gate = x_spectralEntropy2 - gate;    % 减去门限

% 计算过0的点
jndex = 1;
for index  = 2:length(x_SE_minus_gate)
    if x_SE_minus_gate(index-1) * x_SE_minus_gate(index) < 0
        cross_zero(jndex) = index;
        y_cross_zero(jndex) = gate;
        jndex = jndex+1;
    end
end
x_cross_zero = cross_zero/ (round(fs / len_inc));

% 是否输出语音
if false
    gate_audio = sum(x_frame_pow) / (length(x_frame_pow) * 2);
    file_nums = 1;
    for index = 2:2:length(cross_zero)-1
        temp_wave = x(cross_zero(index) * len_inc : cross_zero(index+1) * len_inc); % 片段波形
        temp_pow = x_frame_pow(cross_zero(index):cross_zero(index+1));              % 片段短时能量
        if (sum(temp_pow) / length(temp_pow)) > gate_audio || false                 % 判断是否是语音
            str_file_nums = num2str(file_nums);
            filename = strcat("subAudio_omega",str_file_nums,".wav");
            audiowrite(filename, temp_wave, fs);
            file_nums = file_nums + 1;
        end
    end
end
%% 绘图
figure();
% 时域波形
x_axis = 1:length(x);
subplot(2,2,1);
plot(x_axis / fs, x);
title("时域波形")
xlabel("time/s");

% 第n帧波形
n = ceil(length(x_frame(:,1)) / 4);
x_axis1 = 1:len_frame;
x_n_frame = x_frame(n,:);
subplot(2,2,2);
plot(x_axis1, x_n_frame);
title("第n帧波形")

% 第n帧波形 频域
x_axis1 = 1:len_frame;
x_n_frame_freq = abs(x_frame_freq(n,:));
subplot(2,2,3);
plot(x_axis1, x_n_frame_freq);
title("第n帧波形 频域")

% 短时功率谱
x_axis2 = 1:length(x_frame(:,1));
subplot(2,2,4);
plot(x_axis2 / round(fs / len_inc), x_frame_pow);
title("功率谱")
xlabel("time/s");

% Spectral entropy
figure();
subplot(2,1,1);
x_axis3 = x_axis2 / (round(fs / len_inc));
plot(x_axis3, x_spectralEntropy);
title("Spectral entropy")
xlabel("时间/s");
ylabel("Spectral entropy");

% Spectral entropy with build-in func
subplot(2,1,2);
plot(x_axis3, x_spectralEntropy0);
title("Spectral entropy with build-in func")
xlabel("时间/s");
ylabel("Spectral entropy");

figure();
subplot(111);
plot(x_axis3, x_spectralEntropy2);
title("filtered Spectral entropy with build-in func")
xlabel("时间/s");
ylabel("Spectral entropy");
hold on;
scatter(x_cross_zero, y_cross_zero);
hold off;
