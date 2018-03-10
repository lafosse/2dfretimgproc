function initialize_data(svd, dark_current, transform, xform_mat)
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

%% Find and Delete Previous Versions of '.tif' Images
%  In order to write mulitple pages (frames) to a '.tif' requires appending
%  them during the writing process.  Therefore, it is imperative to delete
%  previous versions of the '.tif' in order to write a newly processed
%  '.tif' file.

% * Tries to find the specific '.tif' files and delete them.
% try  
%     delete('donor.tif');   % donor image
% end
% try
%     delete('fret.tif');  % FRET image
% end
% try
%     delete('acceptor.tif');  % acceptor image
% end
try %#ok<*TRYNC>
    delete('donor_sc.tif');   % shade corrected donor image
end
try
    delete('fret_sc.tif');  % shade corrected FRET image
end
try
    delete('acceptor_sc.tif');  % shade corrected acceptor image
end
try
    delete('donor_transformed.tif');   % transformed donor image
end

%%
%#ok<*NASGU>
%#ok<*DIMTRNS>
%% - Select Data to Import
if exist('img_data.mat','file') == 2
    % Construct a questdlg with three options
    choice = questdlg(sprintf(['An "image data" file was found in the working path. Would you like to use these images or select new images?\n\n', ...
                       'WARNING: If the user selects to use the existing ?img_data.mat? file, MATLAB will search the whole set path to find files with the specified file name within the configuration file. If multiple files within the set path share the same filename as listed in the configuration file, then MATLAB may grab the image data from the wrong file. Please make sure only the files the user wishes to process are within the set path.']), ...
        'Select Images', ...
        'Use "img_data.mat"','Select New Images','Use "img_data.mat"');
    % Handle response
    switch choice
        case 'Use "img_data.mat"'
            disp('Using images from "img_data.mat".')
            run = load('img_data.mat');
            imgs = run.image_data{1,1};

            file_tif_donor = imgs.donor;
            file_tif_fret = imgs.fret;
            file_donor_shade = imgs.donor_shade;
            file_fret_shade = imgs.fret_shade;

            imgInfoA = imfinfo(file_tif_donor);
            imgInfoB = imfinfo(file_tif_fret);
            width = imgInfoA(1).Width;
            height = imgInfoA(1).Height; 
            num_images = length(imgInfoA);

            if svd == 2
                file_tif_acceptor = imgs.acceptor;
                file_acceptor_shade = imgs.acceptor_shade;

                imgInfoC = imfinfo(file_tif_acceptor);
            end

            % Format Shade Correction Images
            donor_shade = imread(file_donor_shade);
            fret_shade = imread(file_fret_shade);

            if svd == 2
                acceptor_shade = imread(file_acceptor_shade);
            end

            % Format Dark Current Images
            if dark_current == 1
                file_donor_dark = imgs.donor_dark;
                file_acceptor_dark = imgs.acceptor_dark;

                donor_dark     = imread(file_donor_dark);
                acceptor_dark  = imread(file_acceptor_dark);
                
                donor_shade = uint16(bsxfun(@minus, double(donor_shade), double(donor_dark)));
                fret_shade = uint16(bsxfun(@minus, double(fret_shade), double(acceptor_dark)));
                
                if svd == 2
                    acceptor_shade = uint16(bsxfun(@minus, double(acceptor_shade), double(acceptor_dark)));
                end
            end

            % Format Transformtion Matrix
            if transform == 1
            %     file_tform = uigetfile('*.mat','Select the transformation matrix');
                trans_matrix = imgs.trans_matrix;
            end

        case 'Select New Images'
            disp('Select new images...')

            disp('Select the donor movie')                
            file_tif_donor = uigetfile('*.tif','Select the donor movie');
            disp('Select the FRET movie')
            file_tif_fret = uigetfile('*.tif','Select the FRET movie');
            disp('Select the donor shade image')
            file_donor_shade = uigetfile('*.tif','Select the donor shade image');
            disp('Select the FRET shade image')
            file_fret_shade = uigetfile('*.tif','Select the FRET shade image');

            imgs = struct;
            imgs.donor = file_tif_donor;
            imgs.fret = file_tif_fret;
            imgs.donor_shade = file_donor_shade;
            imgs.fret_shade = file_fret_shade;

            imgInfoA = imfinfo(file_tif_donor);
            imgInfoB = imfinfo(file_tif_fret);
            width = imgInfoA(1).Width;
            height = imgInfoA(1).Height; 
            num_images = length(imgInfoA);
            save('run_opts.mat', 'num_images','-append');

            if svd == 2
                disp('Select the acceptor movie')
                file_tif_acceptor = uigetfile('*.tif','Select the acceptor movie');
                disp('Select the acceptor shade image')
                file_acceptor_shade = uigetfile('*.tif','Select the acceptor shade image');

                imgs.acceptor = file_tif_acceptor;
                imgs.acceptor_shade = file_acceptor_shade;

                imgInfoC = imfinfo(file_tif_acceptor);
            end

            % Format Shade Correction Images
            donor_shade = imread(file_donor_shade);
            fret_shade = imread(file_fret_shade);

            if svd == 2
                acceptor_shade = imread(file_acceptor_shade);
            end

            % Format Dark Current Images
            if dark_current == 1
                disp('Select the dark current image for the donor channel')
                file_donor_dark = uigetfile('*.tif','Select the dark current image for the donor channel');
                disp('Select the dark current image for the acceptor channel')
                file_acceptor_dark = uigetfile('*.tif','Select the dark current image for the acceptor channel');

                imgs.donor_dark = file_donor_dark;
                imgs.acceptor_dark = file_acceptor_dark;

                donor_dark     = imread(file_donor_dark);
                acceptor_dark  = imread(file_acceptor_dark);
                
                donor_shade = uint16(bsxfun(@minus, double(donor_shade), double(donor_dark)));
                fret_shade = uint16(bsxfun(@minus, double(fret_shade), double(acceptor_dark)));
                
                if svd == 2
                    acceptor_shade = uint16(bsxfun(@minus, double(acceptor_shade), double(acceptor_dark)));
                end
            end

            % Format Transformtion Matrix
            if transform == 1
            %     file_tform = uigetfile('*.mat','Select the transformation matrix');
                trans_matrix = importdata(xform_mat);

                imgs.trans_matrix = trans_matrix;
            end

            image_data = {imgs};
            save('img_data.mat', 'image_data')
    end
else

    disp('Select the donor movie')       
    file_tif_donor = uigetfile('*.tif','Select the donor movie');
    disp('Select the FRET movie')
    file_tif_fret = uigetfile('*.tif','Select the FRET movie');
    disp('Select the donor shade image')
    file_donor_shade = uigetfile('*.tif','Select the donor shade image');
    disp('Select the FRET shade image')
    file_fret_shade = uigetfile('*.tif','Select the FRET shade image');

    imgs = struct;
    imgs.donor = file_tif_donor;
    imgs.fret = file_tif_fret;
    imgs.donor_shade = file_donor_shade;
    imgs.fret_shade = file_fret_shade;

    imgInfoA = imfinfo(file_tif_donor);
    imgInfoB = imfinfo(file_tif_fret);
    width = imgInfoA(1).Width;
    height = imgInfoA(1).Height; 
    num_images = length(imgInfoA);
    save('run_opts.mat', 'num_images','-append');

    if svd == 2
        disp('Select the acceptor movie')
        file_tif_acceptor = uigetfile('*.tif','Select the acceptor movie');
        disp('Select the acceptor shade image')
        file_acceptor_shade = uigetfile('*.tif','Select the acceptor shade image');

        imgs.acceptor = file_tif_acceptor;
        imgs.acceptor_shade = file_acceptor_shade;

        imgInfoC = imfinfo(file_tif_acceptor);
    end

    % Format Shade Correction Images
    donor_shade = imread(file_donor_shade);
    fret_shade = imread(file_fret_shade);

    if svd == 2
        acceptor_shade = imread(file_acceptor_shade);
    end

    % Format Dark Current Images
    if dark_current == 1
        disp('Select the dark current image for the donor channel')
        file_donor_dark = uigetfile('*.tif','Select the dark current image for the donor channel');
        disp('Select the dark current image for the acceptor channel')
        file_acceptor_dark = uigetfile('*.tif','Select the dark current image for the FRET/acceptor channel');

        imgs.donor_dark = file_donor_dark;
        imgs.acceptor_dark = file_acceptor_dark;

        donor_dark     = imread(file_donor_dark);
        acceptor_dark  = imread(file_acceptor_dark);

        donor_shade = uint16(bsxfun(@minus, double(donor_shade), double(donor_dark)));
        fret_shade = uint16(bsxfun(@minus, double(fret_shade), double(acceptor_dark)));

        if svd == 2
            acceptor_shade = uint16(bsxfun(@minus, double(acceptor_shade), double(acceptor_dark)));
        end
    end

    % Format Transformtion Matrix
    if transform == 1
    %     file_tform = uigetfile('*.mat','Select the transformation matrix');
        trans_matrix = importdata(xform_mat);

        imgs.trans_matrix = trans_matrix;
    end

    image_data = {imgs};
    save('img_data.mat', 'image_data')

end

%% - Configure Shade Images

[n,m] = size(donor_shade);

donor_shade_avg = mean(reshape(donor_shade, n*m, 1));  % average donor intensity
if transform == 1
    donor_shade = imtransform(donor_shade, trans_matrix,'XData',[1 m],'YData',[1 n],'FillValues',0);
%     Rout = imref2d(size(donor_shade),[1 m],[1 n]);
%     donor_shade = imwarp(donor_shade,trans_matrix,'OutputView',Rout,'FillValues',0);
end
donor_shade_norm = double(donor_shade) / donor_shade_avg;  % normalized donor shade image

fret_shade_avg = mean(reshape(fret_shade, n*m, 1));  % average fret intensity
fret_shade_norm = double(fret_shade) / fret_shade_avg;  % normalized fret shade image

if svd == 2
    acceptor_shade_avg = mean(reshape(acceptor_shade, n*m, 1)); % average acceptor intensity
    acceptor_shade_norm = double(acceptor_shade) / acceptor_shade_avg; % normalized acceptor shade image
end


%% Breakup donor, FRET, and acceptor Excitation Images Into Managable Number of Frames
% Matlab has limited memory and therefore a maximum possible array size
% which is computer dependent.  Consequently, huge '.tif' files may be too
% large to read into a single array.  Therefore, this code reads in the
% '.tif' files in chunks with a 'for' loop to avoid 'out of memory' errors.

% * A larger value for 'loop' will decrease the memory load on Matlab, but will increase computation time
% * A smaller value for 'loop' could produce memory errors but will decrease computation time 

loop = 9;       % number of subsection of frames

% set number of sub-sections to process sub-total number of frames in '.tif' stack
if num_images <= 3*loop
    num_images_sub = num_images;
    loop = 1;
else
    num_images_sub = floor(num_images/loop);
end

for i = 1:loop
    fprintf('Current Loop Number: %d of %d \r',i,loop)  % display loop number in console

    if i == loop
        ind = (i-1)*(num_images_sub) + 1:num_images;  % indices of "remaining" subsection of frames in last loop
    else
        ind = (i-1)*(num_images_sub) + 1:num_images_sub*i;  % indices of subsection of frames for current loop
    end

    %% Donor and FRET Processing
    donor = zeros(height, width, length(ind), 'uint16');  % empty matrix for donor preallocated for speed
    FRET = zeros(height, width, length(ind), 'uint16');  % empty matrix for fret preallocated for speed
    
    for j = ind
        donor(:,:,find(ind==j,1,'first')) = imread(file_tif_donor, 'Index', j, 'Info', imgInfoA);
        FRET(:,:,find(ind==j,1,'first')) = imread(file_tif_fret, 'Index', j, 'Info', imgInfoB);
    end

    % Apply Dark Current Correction to Donor and FRET
    if dark_current == 1
        donor = uint16(bsxfun(@minus, donor, donor_dark));
        FRET = uint16(bsxfun(@minus, FRET, acceptor_dark));
    end

    % Apply the Transformation to the Donor Image
    [n,m,~] = size(donor);
    if transform == 1
        donor_transformed = imtransform(donor,trans_matrix,'XData',[1 m],'YData',[1 n],'FillValues',0);
%         Rout = imref2d(size(donor),[1 m],[1 n]);
%         donor = imwarp(donor,trans_matrix,'OutputView',Rout,'FillValues',0);
    end

    % Write Donor and FRET to '.tif' files
    for j = 1:length(ind)
        imwrite(donor(:,:,j), 'donor.tif', 'Compression', 'none', 'WriteMode', 'append')  % the raw donor images (donor excitation & emission)
        if transform == 1
            imwrite(donor_transformed(:,:,j),  'donor_transformed.tif',  'Compression', 'none', 'WriteMode', 'append')  % the transformed donor images (donor excitation & emission)
        end
        imwrite(FRET(:,:,j), 'fret.tif', 'Compression', 'none', 'WriteMode', 'append')  % the FRET images (donor excitation, acceptor emission)
    end

    % Apply the Normalized Shade Correction to Donor and FRET
    if transform == 1
        donor_sc = bsxfun(@rdivide, double(donor_transformed), donor_shade_norm);
    else
        donor_sc = bsxfun(@rdivide, double(donor), donor_shade_norm);
    end
    FRET_sc = bsxfun(@rdivide, double(FRET), fret_shade_norm);
    
    % if shade correction image pixel value is 0 (i.e. no reliable signal in pixel)
    % then "kill" pixel by setiing infinite values in shade corrected image
    % (value/0) to 0
    donor_sc(isinf(donor_sc)) = 0;
    donor_sc = uint16(donor_sc);
    FRET_sc(isinf(FRET_sc)) = 0;
    FRET_sc = uint16(FRET_sc);

    % Clear Unnecessary Variables
    donor(:,:,2:end) = [];
    FRET(:,:,2:end) = [];
    if transform == 1
        donor_transformed(:,:,2:end) = [];
    end
    clear('donor', 'FRET')
    if transform == 1
        clear('donor_transformed');
    end

    % Write the Shade Corrected Donor and FRET to '.tif' files
    for j = 1:length(ind)
        imwrite(donor_sc(:,:,j),  'donor_sc.tif',  'Compression', 'none', 'WriteMode', 'append');
        imwrite(FRET_sc(:,:,j), 'fret_sc.tif', 'Compression', 'none', 'WriteMode', 'append');
    end

    % Clear Unnecessary Variables
   donor_sc(:,:,2:end) = [];
   FRET_sc(:,:,2:end) = [];
   clear('donor_sc', 'FRET_sc')


    %% Acceptor Processing

    if svd == 2
        acceptor = zeros(height, width, length(ind), 'uint16');  % empty matrix for acceptor preallocated for speed

        for j = ind
            acceptor(:,:,find(ind==j,1,'first')) = imread(file_tif_acceptor, 'Index', j, 'Info', imgInfoC);
        end

        % Apply Dark Current Correction to Acceptor
        if dark_current == 1
            acceptor = bsxfun(@minus, acceptor, acceptor_dark);
        end

        % Write Acceptor to '.tif' file
        for j = 1:length(ind)
            imwrite(acceptor(:,:,j),  'acceptor.tif',  'Compression', 'none', 'WriteMode', 'append') % the acceptor images (acceptor excitation, acceptor emission)
        end

        % Apply the Normalized Shade Correction to Acceptor Image
        acceptor_sc = uint16(bsxfun(@rdivide, double(acceptor), acceptor_shade_norm));
        
        % if shade correction image pixel value is 0 (i.e. no reliable signal in pixel)
        % then "kill" pixel by setiing infinite values in shade corrected image
        % (value/0) to 0
        acceptor_sc(isinf(acceptor_sc)) = 0;
        acceptor_sc = uint16(acceptor_sc);

        % Clear Unecessary Variables
        acceptor(:,:,2:end) = [];
        clear('acceptor')

        % Write the Shade Corrected Acceptor '.tif' file
        for j = 1:length(ind)
            imwrite(acceptor_sc(:,:,j), 'acceptor_sc.tif', 'Compression', 'none', 'WriteMode', 'append');
        end

        % Clear Unecessary Variables
        acceptor_sc(:,:,2:end) = [];
        clear('acceptor_sc')
    end
    
end
