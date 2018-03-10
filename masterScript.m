function masterScript
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
%% --- Initial processing options --- %%
% check if run_opts.config exists
if exist('run_opts.mat','file') == 2
    % Construct a questdlg with three options
    choice = questdlg('A "run options" file was found in the working path. Would you like to use the options from this file, or select new options?', ...
        'Options Configuration', ...
        'Use "run_opts.mat"','Select New Options','Cancel','Cancel');
    % Handle response
    switch choice
        case 'Use "run_opts.mat"'
            disp('Using options from "run_opts.mat".')
            run = load('run_opts.mat');
            opt = run.opts{1,1};
        case 'Select New Options'
            disp('Select new options...')
            opt = optionsGUI;
        case 'Cancel'
            disp('Exiting Processing.')
            return
    end
else
    opt = optionsGUI;
end

if ~isstruct(opt)
    disp('Image Processing Cancelled.')
    return
end

num_fields = length(fieldnames(opt));
if num_fields ~= 11
    error('Image Processing Cancelled.');
end

% specification of processing of single chain or dual chain biosensors
single_vs_dual    = opt.svd;
% incorporate photobleach correction into processing
photobleach       = opt.photobleach;
% incorporate registration of channels by translations into processing via
% automatic registration or manual registration
register_channels = opt.reg_option;
% apply a filter to ratio image
filter            = opt.filter;
% incorporate dark current/no light correction into processing
dark_current      = opt.dark;
% selection of whether to use a single mask for each channel in the
% processing or separate masks for each channel
one_mask          = opt.one_mask;
% selection of fret/donor, donor/fret, fret/acceptor, and acceptor/fret
ratio_type        = opt.ratios;
% use transformation matrix to align images from two cameras
align_cameras     = opt.align_cams;
xform_mat         = opt.xform_mat;
% bleedthrough coefficients for dual chain biosensor processing
alpha             = opt.alpha;
beta              = opt.beta;


%% --- Specification of channel names --- %%
% nameList = channel_specify;


%% --- Specification of working directory --- %%
% Select working directory where images to be processed are located and where new files will be saved
disp('Select working directory to save images inside')
prev_dir = cd;
working_dir = uigetdir;
if ~strcmp(prev_dir,working_dir)
    status = movefile('run_opts.mat',working_dir); %#ok<NASGU>
    cd(working_dir);
end
addpath(genpath(working_dir));


%% --- Image splitting and configuration --- %%
disp('Starting Initial Data Configuration');
initialize_data(single_vs_dual, dark_current, align_cameras, xform_mat);


%% --- Region selection & background correction --- %%
disp('Starting Region Selection and Background Subtraction...');
background_subtraction(single_vs_dual);


%% --- Apply threshold masks --- %%
disp('Starting Thresholding/Masking GUI...');
% check if necessary masks already exist
if opt.one_mask == 1
    condition = exist('maskfor_.tif','file');
    cond_opt = 1;
else
    if opt.svd == 1
        condition = (exist('maskfor_donor.tif','file') && exist('maskfor_fret.tif','file'));
        cond_opt = 2;
    else
        condition = (exist('maskfor_donor.tif','file') && exist('maskfor_fret.tif','file') && exist('maskfor_acceptor.tif','file'));
        cond_opt = 3;
    end
end
% if necessary masks exist, ask user if they would like to use them or
% generate new masks
gen_new_masks = 1;
if condition
    % Construct a questdlg with two options
    choice = questdlg('Masks of the required name were found in the working path. Use these masks?', ...
        'WARNING', ...
        'Use Masks','Generate New Masks','Exit Processing','Use Masks');
    % Handle response
    switch choice
        case 'Use Masks'
            gen_new_masks = mask_frame_size_checker(cond_opt);
        case 'Generate New Masks'
        case 'Exit Processing'
            disp('Exiting Processing.')
            return
    end
end
if gen_new_masks == 1
    while 1
        frames_of_interest = MovThresh;
        if frames_of_interest == 0
            % Construct a questdlg with two options
            choice = questdlg('No masks generated. Re-open MovThresh to generate new masks or exit porcessing?', ...
                'WARNING', ...
                'Open MovThresh','Exit Processing','Open MovThresh');
            % Handle response
            switch choice
                case 'Open MovThresh'
                    continue
                case 'Exit Processing'
                    disp('Exiting Processing.')
                    return
            end
        else
            break
        end
    end
    waitfor(frames_of_interest)
else
    run = load('run_opts.mat');
    try 
        frames_of_interest = run.foi;
    catch
        frames_of_interest = zeros(run.num_images,1);
        for i = 1:run.num_images
            frames_of_interest(i) = i;
        end
    end
    clear run
end
mask_images(single_vs_dual,one_mask,frames_of_interest);


%% --- Registration --- %%
if register_channels == 1
    disp('Starting Registration...');
    handle = registrationGUI;
    waitfor(handle);
elseif register_channels == 3
    disp('Starting Registration...');
    auto_registration;
end


%% --- Photobleach correction --- %%
if photobleach == 1
    disp('Starting Photobleach Correction...');
    photobleach_correction(single_vs_dual, register_channels);
end


%% --- Ratioing images & corrected FRET--- %%
disp('Ratioing Images and/or calculating corrected FRET...');
run = load('run_opts.mat');
photobleach = run.opts{1,1}.photobleach;
clear run
ratio_images(single_vs_dual, register_channels, photobleach, ratio_type, alpha, beta);


%% --- Apply filter to ratio image --- %%
if filter == 1
    handle = filterGUI;
    waitfor(handle);
end


%% --- End --- %%
input('Press "Enter" to close all windows and finish','s');
close all;