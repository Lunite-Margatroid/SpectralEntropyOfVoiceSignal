# Spectral Entropy

## 信息熵

对于一个离散的随机变量X，设其概率分布为$f(X) = P(X = x_i) = p_i$

信息熵
$$
H(x) = -\Sigma_{i = 1}^{n}p_ilog_2p_i
$$


## Spectral Entropy 谱熵

计算每一帧语音信号的Spectral Entropy

第n帧语音信号x~n~  帧长为l

1、求功率谱

​	(1) 离散傅里叶变换

​	(2) 取模 平方

​	(3) 除以帧长 得到功率谱

2、求能量概率分布 p

​	(1) 功率谱除以总能量

此时$\Sigma p_n(i) = 1$

3、带入信息熵公式



反应信号能量关于频率分布的复杂度。

大概是噪声谱熵高、元音谱熵低。我也不清楚。

## Code

### 读取音频

```matlab
[x, fs] = audioread("audio1.wav");
```

<img src=".\chart\练习生_时域波形.png" alt="时域音频" style="zoom:200%;" />

### 分帧

```matlab
%% 分帧
len_win = fs / 40;                  % 窗宽    25ms
len_frame = len_win;                % 帧长    25ms
len_inc = floor(len_frame * 0.8);   % 帧移    20ms
win = hamming(len_win);             % 海明窗
x_frame = enframe(x, win, len_inc); % 分帧
```

```matlab
function [y_data ] = enframe(x,win,inc)
% in：
    % x：语音信号
    % win：窗函数或者帧长
    % inc：帧移
% out:
    % 分帧后的数组（帧数×帧长）
% ===================================================
 L = length(x(:));          % 数据的长度
 nwin = length(win);        % 取窗长, 数字的长度是1
 if (nwin == 1)             % 判断有无窗函数，若为1，表示没有窗函数
     wlen = win;            % 没有，帧长等于win
 else
     wlen = nwin;           % 有窗函数，帧长等于窗长
 end
 
 if (nargin <3)             % 如果只有两个参数，inc = 帧长
    inc = len;
 end
 
 fn = floor((L - wlen)/inc) + 1;  % 帧数
 
 y_data = zeros(fn,wlen);       % 初始化，fn行，wlen列
 indf = ((0:(fn - 1))*inc)';    % 每一帧在数据y中开始位置的指针
 inds = 1:wlen;                 % 每一帧的数据位置为1至wlen
 indf_k = indf(:,ones(1,wlen));  % 将indf扩展乘fn*wlen的矩阵，每一列的数值都和原indf一样
 inds_k = inds (ones(fn,1), : ); % 将inds扩展乘fn*wlen的矩阵，每一行的数值都和原inds一样
 y_data(:) = x(indf_k + inds_k);
 
 if (nwin >1)  % 若参数中有窗函数，把每帧乘以窗函数
     w = win(:)';
     y_data = y_data.*w(ones(fn,1),:);
end
```

![第n帧时域波形](.\chart\练习生_第n帧时域波形.png)

### 离散傅里叶变换

```matlab
x_frame_freq = zeros(length(x_frame(:,1)), len_frame);
for index = 1:length(x_frame(:,1))
    x_frame_freq(index, :) = fft(x_frame(index, :));
end
```

![第n帧频域波形](.\chart\练习生_第n帧频谱.png)

### 计算谱熵

```matlab
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
```
![谱熵](.\chart\练习生_熵谱.png)
### 使用内建函数一步到位

```matlab
% Spectral entropy with build-in func
x_spectralEntropy0 = spectralEntropy(x ,fs, ...
    Window = win, OverlapLength = len_frame-len_inc, ...
    Range = [62.5, 5000]);      % 只要62.5Hz - 5000Hz的声音
```
![谱熵](.\chart\练习生_熵谱0.png)
### 端点检测

```matlab
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
```
![谱熵](.\chart\练习生_熵谱_标注.png)

### 分段输出音频

```matlab
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
```

## Summarize

<img src=".\chart\练习生_时域波形.png" alt="时域音频" style="zoom:200%;" />

![谱熵](.\chart\练习生_熵谱0.png)

<font size = 4>观察时域波形和谱熵，貌似噪声的谱熵高一些。把低谱熵端输出。</font>



## 示例

### 示例1

<font size = 8>例句: 全民制作人们，大家好！我是练习时长两年半的个人练习生，蔡徐坤。喜欢唱、跳、rap、篮球。music！</font>

<iframe src=".\示例1音频\audio1.wav"></iframe>

<font size = 7>分割：</font>

<font size = 7>全民制作人们大家好</font>

<iframe src=".\示例1音频\subAudio_omega1.wav"></iframe>

<font color = blue size = 7>ao</font>

<iframe src=".\示例1音频\subAudio_omega2.wav"></iframe>
<font size = 7>我</font>
<iframe src=".\示例1音频\subAudio_omega3.wav"></iframe>
<font size = 7>是练</font>
<iframe src=".\示例1音频\subAudio_omega4.wav"></iframe>
<font color = red size = 7>习</font> 

<font size = 7>时长</font>
<iframe src=".\示例1音频\subAudio_omega5.wav"></iframe>
<font size = 7>两</font>
<iframe src=".\示例1音频\subAudio_omega6.wav"></iframe>
<font size = 7>年半</font>
<iframe src=".\示例1音频\subAudio_omega7.wav"></iframe>
<font size = 7>的</font>
<iframe src=".\示例1音频\subAudio_omega8.wav"></iframe>
<font size = 7>个人练习</font>
<iframe src=".\示例1音频\subAudio_omega9.wav"></iframe>
<font size = 7>生</font>
<iframe src=".\示例1音频\subAudio_omega10.wav"></iframe>
<font size = 7>蔡徐</font>
<iframe src=".\示例1音频\subAudio_omega11.wav"></iframe>
<font size = 7>坤</font>
<iframe src=".\示例1音频\subAudio_omega12.wav"></iframe>
<font color = red size = 7>喜欢</font>

<font size = 7>唱</font>
<iframe src=".\示例1音频\subAudio_omega13.wav"></iframe>
<font size = 7>跳</font>
<iframe src=".\示例1音频\subAudio_omega14.wav"></iframe>
<font size = 7>rap</font>
<iframe src=".\示例1音频\subAudio_omega15.wav"></iframe>
<font size = 7>篮球</font>
<iframe src=".\示例1音频\subAudio_omega16.wav"></iframe>
<font size = 7>music</font>
<iframe src=".\示例1音频\subAudio_omega17.wav"></iframe>

### 示例2

<font size = 8>例句：Ad astra abyssosque. Welcome to the adventurer's guild.</font>

<iframe src=".\示例2音频\E_audio.wav"></iframe>
<font size = 7>Ad</font>
<iframe src=".\示例2音频\E_subAudio_omega1.wav"></iframe>
<font size = 7>as</font>
<iframe src=".\示例2音频\E_subAudio_omega2.wav"></iframe>
<font size = 7>t</font>
<iframe src=".\示例2音频\E_subAudio_omega3.wav"></iframe>
<font size = 7>ra</font>
<iframe src=".\示例2音频\E_subAudio_omega4.wav"></iframe>
<font size = 7>abys</font>
<iframe src=".\示例2音频\E_subAudio_omega5.wav"></iframe>
<font size = 7>sos</font>
<iframe src=".\示例2音频\E_subAudio_omega6.wav"></iframe>
<font color = red size = 7>que</font>

<font size = 7>Wel</font>
<iframe src=".\示例2音频\E_subAudio_omega7.wav"></iframe>
<font size = 7>come</font>
<iframe src=".\示例2音频\E_subAudio_omega8.wav"></iframe>
<font size = 7>to the adven</font>
<iframe src=".\示例2音频\E_subAudio_omega9.wav"></iframe>
<font size = 7>turer's</font>

<iframe src=".\示例2音频\E_subAudio_omega10.wav"></iframe>
<font size = 7>guild</font>
<iframe src=".\示例2音频\E_subAudio_omega11.wav"></iframe>
### 示例3

<font size = 8>例句:  星と深淵に目指せ！ようこそ冒険者協会へ。</font>

<font size = 8>ho shi to shin en ni me za se   you ko so bou ken shya kyou kai e</font>

<iframe src=".\示例3音频\J_audio.wav"></iframe>


<font size = 7>ho</font>
<iframe src=".\示例3音频\J_subAudio_omega1.wav"></iframe>
<font size = 7>o sh</font>
<iframe src=".\示例3音频\J_subAudio_omega2.wav"></iframe>
<font size = 7>i</font>
<iframe src=".\示例3音频\J_subAudio_omega3.wav"></iframe>
<font color = red size = 7>to</font>

<font size = 7>shin en ni me za s</font>
<iframe src=".\示例3音频\J_subAudio_omega4.wav"></iframe>
<font size = 7>e</font>
<iframe src=".\示例3音频\J_subAudio_omega5.wav"></iframe>
<font color = blue size = 7>e</font>

<iframe src=".\示例3音频\J_subAudio_omega6.wav"></iframe>
<font size = 7>yo</font>
<iframe src=".\示例3音频\J_subAudio_omega7.wav"></iframe>
<font size = 7>u</font>
<iframe src=".\示例3音频\J_subAudio_omega8.wav"></iframe>
<font size = 7>ko</font>
<iframe src=".\示例3音频\J_subAudio_omega9.wav"></iframe>
<font size = 7>so</font>
<iframe src=".\示例3音频\J_subAudio_omega10.wav"></iframe>

<font size = 7>bou</font>
<iframe src=".\示例3音频\J_subAudio_omega11.wav"></iframe>
<font size = 7>ken shy</font>
<iframe src=".\示例3音频\J_subAudio_omega12.wav"></iframe>
<font size = 7>a</font>
<iframe src=".\示例3音频\J_subAudio_omega13.wav"></iframe>
<font size = 7>kyou k</font>
<iframe src=".\示例3音频\J_subAudio_omega14.wav"></iframe>
<font size = 7>ai e</font>
<iframe src=".\示例3音频\J_subAudio_omega15.wav"></iframe>
<font color = blue size = 7>e</font>

<iframe src=".\示例3音频\J_subAudio_omega16.wav"></iframe>

## Summarize2

从汉语、日语和英语的分割情况来看，基本是按照一个音节一个音节来分割的。推测，元音的谱熵相比辅音要低一些。

到底元音辅音，清音浊音、噪音的谱熵有什么特征，等老师来解答吧。