function mask_images(svd, one_mask, foi)
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

%% Breakup donor, FRET, and acceptor Images Into Managable Number of Frames
% Matlab has limited memory and therefore a maximum possible array size
% which is computer dependent.  Consequently, huge '.tif' files may be too
% large to read into a single array.  Therefore, this code reads in the
% '.tif' files in chunks with a 'for' loop to avoid 'out of memory' errors.

% * A larger value for 'loop' will decrease the memory load on Matlab, but will increase computation time
% * A smaller value for 'loop' could produce memory errors but will decrease computation time 

loop = 6;       % number of subsection of frames to process at a time
view_fig = 0;   % to view figures set to 1

% record frames of interest in 'run_opts.mat'
save('run_opts.mat','foi','-append');

% import necessary images into variables
file_tifA = 'donor_scbg_roi.tif';
file_tifB = 'fret_scbg_roi.tif';
if svd == 2
    file_tifC = 'acceptor_scbg_roi.tif';
end

if one_mask == 0
    file_tifD = 'maskfor_donor.tif';
    file_tifE = 'maskfor_fret.tif';
    if svd == 2
        file_tifF = 'maskfor_acceptor.tif';
    end
else
    file_tifG = 'maskfor_.tif';
end
    
%% Find and Delete Previous Versions of '.tif' Images
%  In order to write mulitple pages (frames) to a '.tif' requires appending
%  them during the writing process.  Therefore, it is imperative to delete
%  previous versions of the '.tif' in order to write a newly processed
%  '.tif' file.

% * Tries to find the specific '.tif' files and delete them.
try  %#ok<*TRYNC>
    delete('donor_masked.tif');   % masked donor image
end
try
    delete('fret_masked.tif');  % masked FRET image
end
try
    delete('acceptor_masked.tif');  % masked acceptor image
end

%%
infoA = imfinfo(file_tifA);
infoB = imfinfo(file_tifB);

mImage = infoA(1).Width;   % number of pixels in the X direction 
nImage = infoA(1).Height;  % number of pixels in the Y direction 
num_images = length(foi);  % total number of frames in '.tif' stack

if one_mask == 0
    infoD = imfinfo(file_tifD);
    infoE = imfinfo(file_tifE);
else
    infoG = imfinfo(file_tifG);
end

if svd == 2
    infoC = imfinfo(file_tifC);
    if one_mask == 0
        infoF = imfinfo(file_tifF);
    end
end

%% Preallocate Variables for Performance
area_N = zeros(num_images,1);  % empty matrix preallocated for speed (normalized cell area)
intensity_donor = zeros(num_images,3);  % empty matrix preallocated for speed (intensity calculations for donor)
intensity_fret = zeros(num_images,3);  % empty matrix preallocated for speed (intensity caluclations for FRET)
intensity_acceptor = zeros(num_images,3);  % empty matrix preallocated for speed (intensity calculations for acceptor)

% set number of sub-sections to process sub-total number of frames in '.tif' stack
if num_images <= 3*loop
    num_images_sub = num_images;
    loop = 1;
else
    num_images_sub = floor(num_images/loop);
end

for i = 1:loop
    fprintf('Current Loop Number: %d of %d \r',i,loop)
    
    if i == loop
        ind = (i-1)*(num_images_sub) + 1:num_images;  % indices of "remaining" subsection of frames in last loop
    else
        ind = (i-1)*(num_images_sub) + 1:num_images_sub*i;  % indices of subsection of frames for current loop
    end
    
    %%
    donor_matrix = zeros(nImage, mImage, length(ind), 'uint16');
    fret_matrix = zeros(nImage, mImage, length(ind), 'uint16');
    if svd == 2
        acceptor_matrix = zeros(nImage, mImage, length(ind), 'uint16');
    end    
    
    if one_mask == 0
        donor_mask = zeros(nImage, mImage, length(ind), 'uint16');
        fret_mask = zeros(nImage, mImage, length(ind), 'uint16');
        if svd == 2
            acceptor_mask = zeros(nImage, mImage, length(ind), 'uint16');
        end
    else
        single_mask = zeros(nImage, mImage, length(ind), 'uint16');
    end  
    
    for j = ind
        donor_matrix(:,:,find(ind==j,1,'first')) = imread(file_tifA, 'Index', foi(j), 'Info', infoA);  % read the correct subsection of frames of image A
        fret_matrix(:,:,find(ind==j,1,'first')) = imread(file_tifB, 'Index', foi(j), 'Info', infoB);  % read the correct subsection of frames of image B
        if svd == 2
            acceptor_matrix(:,:,find(ind==j,1,'first')) = imread(file_tifC, 'Index', foi(j), 'Info', infoC);  % read the correct subsection of frames of image C
        end
        
        if one_mask == 0
            donor_mask(:,:,find(ind==j,1,'first')) = imread(file_tifD, 'Index', j, 'Info', infoD);  % read the correct subsection of frames of image D
            fret_mask(:,:,find(ind==j,1,'first')) = imread(file_tifE, 'Index', j, 'Info', infoE);  % read the correct subsection of frames of image E
            if svd == 2
                acceptor_mask(:,:,find(ind==j,1,'first')) = imread(file_tifF, 'Index', j, 'Info', infoF);  % read the correct subsection of frames of image F
            end
        else
            single_mask(:,:,find(ind==j,1,'first')) = imread(file_tifG, 'Index', j, 'Info', infoG);  % read the correct subsection of frames of image G
        end
    end
    
    %% Apply Mask to Shade Corrected, Background Subtracted, Cropped, and Registered* Matrices
    if one_mask == 0
        donor_mk = donor_matrix .* donor_mask;
        fret_mk = fret_matrix .* fret_mask;
        if svd == 2
            acceptor_mk = acceptor_matrix .* acceptor_mask;
        end
    else
        donor_mk = donor_matrix .* single_mask;
        fret_mk = fret_matrix .* single_mask;
        if svd == 2
            acceptor_mk = acceptor_matrix .* single_mask;
        end
    end
    
    %%
    % Reduce or clear unnecessary variables
    if i == 1 && view_fig == 1
        donor_matrix(:,:,2:end) = []; %#ok<*NASGU>
        fret_matrix(:,:,2:end) = [];
    else
        clear('donor_matrix', 'fret_matrix');
    end
    
    if svd == 2
        if i == 1 && view_fig == 1
            acceptor_matrix(:,:,2:end) = [];
        else
            clear('acceptor_matrix');
        end
    end
    
    %% Write the Masked Matrices to Images
    for j = 1:length(ind)
        
        try 
            imwrite(donor_mk(:,:,j), 'donor_masked.tif', 'Compression', 'none', 'WriteMode', 'append');
        catch
            pause(1)
            fprintf('DONORmask Iteration value: %i\n', j);
            imwrite(donor_mk(:,:,j), 'donor_masked.tif', 'Compression', 'none', 'WriteMode', 'append');
        end
        
        try 
            imwrite(fret_mk(:,:,j), 'fret_masked.tif', 'Compression', 'none', 'WriteMode', 'append');
        catch
            pause(1)
            fprintf('FRETmask Iteration value: %i\n', j);
            imwrite(fret_mk(:,:,j), 'fret_masked.tif', 'Compression', 'none', 'WriteMode', 'append');
        end
        
        if svd == 2
            try 
                imwrite(acceptor_mk(:,:,j), 'acceptor_masked.tif', 'Compression', 'none', 'WriteMode', 'append');
            catch
                pause(1)
                fprintf('ACCEPTORmask Iteration value: %i\n', j);
                imwrite(acceptor_mk(:,:,j), 'acceptor_masked.tif', 'Compression', 'none', 'WriteMode', 'append');
            end
        end
    end   
    
    %% Calculations 
    total_area = sum(reshape(donor_mk > 0, nImage*mImage, 1, length(ind)));
    area_N(ind) = total_area/total_area(1);  % normalized area
    
    d = reshape(donor_mk, nImage*mImage, 1, length(ind)); 
    f = reshape(fret_mk, nImage*mImage, 1, length(ind));
    
    intensity_donor(ind,:) = [squeeze(max(d)), squeeze(min(d)), squeeze(mean(d))];
    intensity_fret(ind,:) = [squeeze(max(f)), squeeze(min(f)), squeeze(mean(f))];
    
    if svd == 2
        a = reshape(acceptor_mk, nImage*mImage, 1, length(ind));
        intensity_acceptor(ind,:) = [squeeze(max(a)), squeeze(min(a)), squeeze(mean(a))];
    end
    
    %%
    % Reduce or clear unnecessary variables
    if i == 1 && view_fig == 1
        donor_mk(:,:,2:end) = [];
        fret_mk(:,:,2:end) = [];
    else
        clear('donor_mk', 'fret_mk');
    end
    
    if svd == 2
        if i == 1 && view_fig == 1
            acceptor_mk(:,:,2:end) = [];
        else
            clear('acceptor_mk');
        end
    end
        
    %% Figures
%     if i == 1 && view_fig == 1
%         f7 = figure('Name', 'Masked Images');
%         subplot(3,2,1); imagesc(donor_matrix(:,:,1)); axis image; colorbar; title('donor_scbg_roi');
%         subplot(3,2,2); imagesc(donor_mk(:,:,1)); axis image; colorbar; title('donor_masked');
%         subplot(3,2,3); imagesc(fret_matrix(:,:,1)); axis image; colorbar; title('FRET_scbg_roi');
%         subplot(3,2,4); imagesc(fret_mk(:,:,1)); axis image; colorbar; title('FRET_masked');
%         if svd == 2
%             subplot(3,3,5); imagesc(acceptor_matrix(:,:,1)); axis image; colorbar; title('acceptor_scbg');
%             subplot(3,3,6); imagesc(acceptor_mk(:,:,1)); axis image; colorbar; title('acceptor_masked');
%         end
%     end
end