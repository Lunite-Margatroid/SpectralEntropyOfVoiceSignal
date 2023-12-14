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
