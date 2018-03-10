function background_subtraction(svd)
% Copyright (c) 2017 Paul LaFosse
%
% Created for use by the Klaus Hahn Lab at the University of
% North Carolina at Chapel Hill
%
% Email Contacts:
% Klaus Hahn: khahn@med.unc.edu
% Paul LaFosse: lafosse@ad.unc.edu
%
% This file is part of a comprehensive package, 2dfretimgproc.
% 2dfretimgproc is a free software package that can be modified/
% distributed under the terms described by the GNU General Public 
% License version 3.0. A copy of this license should have been 
% present within the 2dfretimgproc package. If not, please visit 
% the following link to learn more: <http://www.gnu.org/licenses/>.
%

%#ok<*NASGU>

while 1
    handle = background_subtractionGUI;
    waitfor(handle)
    if exist('region_boxes.txt', 'file') == 2
        % * reads in region boxes and sets variables
        fid = fopen('region_boxes.txt', 'r');
        str = fscanf(fid, '%c');
        expr1 = 'background_box = [(.*)\]r';
        expr2 = 'region_box = [(.*)\]';
        tokens1 = regexp(str, expr1, 'tokens');
        tokens2 = regexp(str, expr2, 'tokens');
        bg = cell2mat(textscan(tokens1{1}{1}, '%d %d %d %d', 'delimiter', ','));
        rg = cell2mat(textscan(tokens2{1}{1}, '%d %d %d %d', 'delimiter', ','));
        X1 = bg(1);
        Y1 = bg(2);
        W1 = bg(3)-1;
        H1 = bg(4)-1;
        X2 = rg(1);
        Y2 = rg(2);
        W2 = rg(3)-1;
        H2 = rg(4)-1;
        fclose(fid);
        break
    else
        disp('No "region_boxes.txt" file found in path...');
        yn = input('Relaunch Background Subtraction GUI to calculate regions? (y/n)','s');
        if ~strcmp(yn,'y')
            error('Script needs "region_boxes.txt" to continue processing. Exiting script...');
        end
    end
end

%% Find and Delete Previous Versions of '.tif' Images
%  To write mulitple pages (frames) to a '.tif' requires appending them
%  during the writing process.  Therefore, it is imperative to delete
%  previous versions of the '.tif' in order to write a newly processed
%  '.tif' file.

% * Tries to find the specific '.tif' files and delete them.
try %#ok<*UNRCH,*TRYNC>
    delete('donor_scbg.tif');   % shade corrected, background subtracted, donor excitation, donor channel emission
end
try
    delete('fret_scbg.tif');  % shade corrected, background subtracted, donor excitation, acceptor channel emission
end
try
    delete('acceptor_scbg.tif');  % shade corrected, background subtracted, acceptor excitation, acceptor channel emission
end
try
    delete('donor_scbg_roi.tif');  % shade corrected, background subtracted, donor excitation, donor channel emission subregion  
end
try
    delete('fret_scbg_roi.tif');  % shade corrected, background subtracted, donor excitation, acceptor channel emission subregion
end
try
    delete('acceptor_scbg_roi.tif');  % shade corrected, background subtracted, acceptor excitation, acceptor channel emission subregion
end


%% Select Data to Import
file_tifA = 'donor_sc.tif';
file_tifB = 'fret_sc.tif';
infoA = imfinfo(file_tifA);  % information of shade corrected donor images
infoB = imfinfo(file_tifB);  % information of shade corrected FRET images
mImage = infoA(1).Width;   % number of pixels in the X direction
nImage = infoA(1).Height;  % number of pixels in the Y direction
num_images = length(infoA);  % total number of frames in '.tif' stack
if svd == 2
    file_tifC = 'acceptor_sc.tif';
    infoC = imfinfo(file_tifC); % information of shade corrected acceptor images
end

%% Breakup donor, FRET, and acceptor Images Into Managable Number of Frames
% Matlab has limited memory and therefore a maximum possible array size
% which is computer dependent.  Consequently, huge '.tif' files may be too
% large to read into a single array.  Therefore, this code reads in the
% '.tif' files in chunks with a 'for' loop to avoid 'out of memory' errors.

% * A larger value for 'loop' will decrease the memory load on Matlab, but will increase computation time
% * A smaller value for 'loop' could produce memory errors but will decrease computation time 

loop = 6;       % number of subsection of frames
view_fig = 0;   % to view figures set to 1. 

% set number of sub-sections to process sub-total number of frames in '.tif' stack
if num_images <= 3*loop
    num_images_sub = num_images;
    loop = 1;
else
    num_images_sub = floor(num_images/loop);
end

for i = 1:loop
    %% Background Subtraction Processing
    fprintf('Current Loop of Background Subtraction: %d of %d \r',i,loop)

    if i == loop  % at last loop
        ind = (i-1)*(num_images_sub) + 1:num_images;  % indices of "remaining" subsection of frames (i.e. num_images/loop ~= integer)
    else
        ind = (i-1)*(num_images_sub) + 1:num_images_sub*i;  % indices of subsection of frames (i.e. length(num_images_sub))
    end

    % Read Data into Variables
    donor_sc  = zeros(nImage, mImage, length(ind), 'uint16');
    fret_sc = zeros(nImage, mImage, length(ind), 'uint16');
    for j = ind
        donor_sc(:,:,find(ind==j,1,'first')) = imread(file_tifA, 'Index', j, 'Info', infoA);
        fret_sc(:,:,find(ind==j,1,'first')) = imread(file_tifB, 'Index', j, 'Info', infoB);
    end

    % Compute average intensity in the Background Subregion and Subtract from the Shade Corrected Images
    donor_sc_bgsub = donor_sc(Y1:ceil(Y1 + H1), X1:ceil(X1 + W1), :);
    fret_sc_bgsub = fret_sc(Y1:ceil(Y1 + H1), X1:ceil(X1 + W1), :);

    [n,m,p] = size(donor_sc_bgsub);
    donor_sc_bgsub_avg = mean(reshape(donor_sc_bgsub,  1, n*m, p));
    fret_sc_bgsub_avg = mean(reshape(fret_sc_bgsub, 1, n*m, p));

    donor_scbg = uint16(bsxfun(@minus, double(donor_sc), donor_sc_bgsub_avg));
    fret_scbg = uint16(bsxfun(@minus, double(fret_sc), fret_sc_bgsub_avg));

    % Reduce or clear unnecessary variables
    if i == 1 && view_fig == 1
        donor_sc(:,:,2:end) = [];
        fret_sc(:,:,2:end) = [];
    else
        clear('donor_sc', 'fret_sc',...
              'donor_sc_bgsub','fret_sc_bgsub');
    end

    % Write the Shade Corrected, Background Subtracted donor and FRET
    % images to '.tif' files
    for j = 1:length(ind)
        try 
            imwrite(donor_scbg(:,:,j), 'donor_scbg.tif',  'Compression', 'none', 'WriteMode', 'append');  % shade corrected, background subtracted donor images
        catch
            pause(1)
            fprintf('DONORscbg Iteration value: %i\n', j);
            imwrite(donor_scbg(:,:,j), 'donor_scbg.tif',  'Compression', 'none', 'WriteMode', 'append');  % shade corrected, background subtracted donor images
        end

        try 
            imwrite(fret_scbg(:,:,j), 'fret_scbg.tif', 'Compression', 'none', 'WriteMode', 'append');  % shade corrected, background subtracted fret images       
        catch
            pause(1)
            fprintf('FRETscbg Iteration value: %i\n', j);
            imwrite(fret_scbg(:,:,j), 'fret_scbg.tif', 'Compression', 'none', 'WriteMode', 'append');  % shade corrected, background subtracted fret images       
        end
        
    end  

    % Acceptor Images
    if svd == 2
        % Read Data into Variables
        acceptor_sc  = zeros(nImage, mImage, length(ind), 'uint16');
        for j = ind
            acceptor_sc(:,:,find(ind==j,1,'first')) = imread(file_tifC, 'Index', j, 'Info', infoC);
        end

        % Compute average intensity in the Background Subregion and Subtract from the Shade Corrected Images
        acceptor_sc_bgsub = acceptor_sc(Y1:ceil(Y1 + H1), X1:ceil(X1 + W1), :);

        acceptor_sc_bgsub_avg = mean(reshape(acceptor_sc_bgsub,  1, n*m, p));

        acceptor_scbg  = uint16(bsxfun(@minus, double(acceptor_sc), acceptor_sc_bgsub_avg));

        % Reduce or Clear Unnecessary Variables
        if i == 1 && view_fig == 1
            acceptor_sc(:,:,2:end) = [];
        else
            clear('acceptor_sc', 'acceptor_sc_bgsub');
        end

        % Write the Shade Corrected, Background Subtracted acceptor
        % images to '.tif' files
        for j = 1:length(ind)
            imwrite(acceptor_scbg(:,:,j), 'acceptor_scbg.tif',  'Compression', 'none', 'WriteMode', 'append');  % shade corrected, background subtracted acceptor images      
        end 
    end

    %% Crop Images to Region of Interest
    donor_scbg_roi = donor_scbg(Y2:ceil(Y2 + H2)-1, X2:ceil(X2 + W2)-1, :);
    fret_scbg_roi = fret_scbg(Y2:ceil(Y2 + H2)-1, X2:ceil(X2 + W2)-1, :); 

    % Reduce or clear unnecessary variables
    if i == 1 && view_fig == 1
        donor_scbg(:,:,2:end) = [];
        fret_scbg(:,:,2:end) = [];
    else
        clear('donor_scbg', 'fret_scbg');
    end   

    % Write the Cropped, Shade Corrected, Background Subtracted donor
    % and FRET images to '.tif' files
    for j = 1:length(ind)
        try 
            imwrite(donor_scbg_roi(:,:,j), 'donor_scbg_roi.tif',  'Compression', 'none', 'WriteMode', 'append')
        catch
            pause(1)
            fprintf('DONOR Iteration value: %i\n', j);
            imwrite(donor_scbg_roi(:,:,j), 'donor_scbg_roi.tif',  'Compression', 'none', 'WriteMode', 'append')
        end
        
        try
            imwrite(fret_scbg_roi(:,:,j), 'fret_scbg_roi.tif', 'Compression', 'none', 'WriteMode', 'append')
        catch
            pause(1)
            fprintf('FRET Iteration value: %i\n', j);
            imwrite(fret_scbg_roi(:,:,j), 'fret_scbg_roi.tif', 'Compression', 'none', 'WriteMode', 'append')
        end            
    end

    % Reduce or clear unnecessary variables
    if i == 1 && view_fig == 1
        donor_scbg_roi(:,:,2:end) = [];
        fret_scbg_roi(:,:,2:end) = [];
    else
        clear('donor_scbg_roi', 'fret_scbg_roi');
    end

    % Acceptor Images
    if svd == 2
        acceptor_scbg_roi = acceptor_scbg(Y2:ceil(Y2 + H2)-1, X2:ceil(X2 + W2)-1, :);

        % Reduce or clear unnecessary variables
        if i == 1 && view_fig == 1
            acceptor_scbg(:,:,2:end) = [];
        else
            clear('acceptor_scbg');
        end   

        % Write the Cropped, Shade Corrected, Background Subtracted
        % acceptor images to '.tif' files
        for j = 1:length(ind)
            imwrite(acceptor_scbg_roi(:,:,j), 'acceptor_scbg_roi.tif',  'Compression', 'none', 'WriteMode', 'append')
        end

        % Reduce or clear unnecessary variables
        if i == 1 && view_fig == 1
            acceptor_scbg_roi(:,:,2:end) = [];
        else
            clear('acceptor_scbg_roi');
        end

    end

    %% Figures
    % * only viewed on first loop and if the variable 'view_fig' is equal to 1.
%     if i == 1 && view_fig == 1
% 
%         if svd == 1
%             f5 = figure('Name', 'Background Corrected');
%             subplot(3,2,1); imagesc(donor_sc(:,:,1)); axis image; colorbar; title('donor_sc');
%             subplot(3,2,2); imagesc(donor_scbg(:,:,1)); axis image; colorbar; title('donor_scbg');
%             subplot(3,2,3); imagesc(fret_sc(:,:,1)); axis image; colorbar; title('FRET_sc');
%             subplot(3,2,4); imagesc(fret_scbg(:,:,1)); axis image; colorbar; title('FRET_scbg');
% 
%             f6 = figure('Name', 'Background Corrected - ROI');
%             subplot(3,2,1); imagesc(donor_scbg(:,:,1)); axis image; colorbar; title('donor_scbg');
%             subplot(3,2,2); imagesc(donor_scbg_roi(:,:,1)); axis image; colorbar; title('donor_scbg-region');
%             subplot(3,2,3); imagesc(fret_scbg(:,:,1)); axis image; colorbar; title('FRET_scbg');
%             subplot(3,2,4); imagesc(fret_scbg_roi(:,:,1)); axis image; colorbar; title('FRET_scbg-region');
%         else
%             f5 = figure('Name', 'Background Corrected');
%             subplot(3,2,1); imagesc(donor_sc(:,:,1)); axis image; colorbar; title('donor_sc');
%             subplot(3,2,2); imagesc(donor_scbg(:,:,1)); axis image; colorbar; title('FRET_scbg');
%             subplot(3,2,3); imagesc(fret_sc(:,:,1)); axis image; colorbar; title('FRET_sc');
%             subplot(3,2,4); imagesc(fret_scbg(:,:,1)); axis image; colorbar; title('FRET_scbg');
%             subplot(3,2,5); imagesc(acceptor_sc(:,:,1)); axis image; colorbar; title('acceptor_sc');
%             subplot(3,2,6); imagesc(acceptor_scbg(:,:,1)); axis image; colorbar; title('acceptor_scbg');
% 
%             f6 = figure('Name', 'Background Corrected - ROI');
%             subplot(3,2,1); imagesc(donor_scbg(:,:,1)); axis image; colorbar; title('donor_scbg');
%             subplot(3,2,2); imagesc(donor_scbg_roi(:,:,1)); axis image; colorbar; title('donor_scbg-region');
%             subplot(3,2,3); imagesc(fret_scbg(:,:,1)); axis image; colorbar; title('FRET_scbg');
%             subplot(3,2,4); imagesc(fret_scbg_roi(:,:,1)); axis image; colorbar; title('FRET_scbg-region');
%             subplot(3,2,5); imagesc(acceptor_scbg(:,:,1)); axis image; colorbar; title('acceptor_scbg');
%             subplot(3,2,6); imagesc(acceptor_scbg_roi(:,:,1)); axis image; colorbar; title('acceptor_scbg-region');
%         end

        % saveas(f5, 'Bkgrnd_corrected.eps');
        % saveas(f6, 'Cell subregion.eps');
%     end
end

end
