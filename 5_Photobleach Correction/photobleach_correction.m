function photobleach_correction(svd, registered)
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

%% --- Photoleach Correction
% construct a questdlg about selecting exclusion criteria
task = questdlg('Would you like to perform automatic photobleach correction or to select exclusion criteria on the photobleach correction curves for each channel?', ...
    'WARNING!', ...
    'Select Exclusion Criteria','Automatic Photobleach Correcton','Automatic Photobleach Correcton');
if strcmp(task,'Select Exclusion Criteria')
    while 1
        handle = photobleachGUI;
        waitfor(handle)
        disp('waitfor called')
        if svd == 1
            if ~exist('donor_pbc.tif','file') || ~exist('fret_pbc.tif','file')
                disp('into if cond')
                % Construct a questdlg
                choice = questdlg('Not all channels have had photobleach corrections applied or files aren"t named properly. Would you like to return to the photobleach correction GUI or continue with photobleach correction?', ...
                    'Warning - Not all necessary images found', ...
                    'Return to GUI','Continue Processing without Photobleach Correction','Continue Processing without Photobleach Correction');
                % Handle response
                switch choice
                    case 'Return to GUI'
                        continue
                    case 'Continue Processing without Photobleach Correction'
                        disp('Ratioing will continue without photobleach correction (run_opts.mat updated)...')
                        load('run_opts.mat');
                        opts{1,1}.photobleach = 0;
                        save('run_opts.mat');
                        clear opts
                        break
                end
            else
                break
            end
        else
            if ~exist('donor_pbc.tif','file') || ~exist('fret_pbc.tif','file') || ~exist('acceptor_pbc.tif','file')
                % Construct a questdlg
                choice = questdlg('Not all channels have had photobleach corrections applied or files aren"t named properly. Would you like to return to the photobleach correction GUI or continue with photobleach correction?', ...
                    'Warning - Not all necessary images found', ...
                    'Return to GUI','Continue Processing without Photobleach Correction','Continue Processing without Photobleach Correction');
                % Handle response
                switch choice
                    case 'Return to GUI'
                        continue
                    case 'Continue Processing without Photobleach Correction'
                        disp('Ratioing will continue without photobleach correction (run_opts.mat updated)...')
                        load('run_opts.mat');
                        opts{1,1}.photobleach = 0;
                        save('run_opts.mat');
                        clear opts
                        break
                end
            else
                break
            end
        end
    end
else
    % Import necessary data
    donor_path = cd;
    if registered ~= 2
        donor_file = 'donor_reg.tif';
    else
        donor_file = 'donor_masked.tif';
    end
    donor_info = imfinfo(fullfile(donor_path, donor_file));
    frames = numel(donor_info);
    if frames < 4
        fprintf(['Photobleach correction requires the image series to have\n',...
            'at least 4 time frames...\n'])
        disp('Ratioing will continue without photobleach correction...')
        load('run_opts.mat');
        opts{1,1}.photobleach = 0;
        save('run_opts.mat');
        clear opts
        return
    end

    fret_path = cd;
    fret_file = 'fret_masked.tif';
    fret_info = imfinfo(fullfile(fret_path ,fret_file));

    I = frames;
    plane = 1:frames;
    plane = plane.';

    % Pre-allocated matrices
    donor_avgIntensity = zeros(1,frames);
    donor_avgIntensity_norm = zeros(1,frames);
    fret_avgIntensity = zeros(1,frames);
    fret_avgIntensity_norm = zeros(1,frames);

    donor_cell = cell(1,frames);
    fret_cell = cell(1,frames);

    if svd == 2
        acceptor_path = cd;
        acceptor_file = 'acceptor_masked.tif';
        acceptor_info = imfinfo(fullfile(acceptor_path, acceptor_file));

        acceptor_avgIntensity = zeros(1,frames);
        acceptor_avgIntensity_norm = zeros(1,frames);

        acceptor_cell = cell(1,frames);
    end

    %% Read data into matrices
    for x=1:frames
        % Calculate average intensity in each frame of each image in order to
        % calculate normalized intensity values across all frames with respect
        % to the first frame
        a = imread(fullfile(donor_path,donor_file),'tif',x,'Info',donor_info);
        donor_cell{x} = a;
        b = a;
        b(b>0) = 1;
        cellarea = sum(b(:));
        donor_avgIntensity(x) = double(sum(a(:)))./cellarea;
        donor_avgIntensity_norm(x) = donor_avgIntensity(x)/donor_avgIntensity(1);

        a = imread(fullfile(fret_path,fret_file),'tif',x,'Info',fret_info);
        fret_cell{x} = a;
        b = a;
        b(b>0) = 1;
        cellarea = sum(b(:));
        fret_avgIntensity(x) = double(sum(a(:)))./cellarea;  
        fret_avgIntensity_norm(x) = fret_avgIntensity(x)/fret_avgIntensity(1);

        if svd == 2
            a = imread(fullfile(acceptor_path,acceptor_file),'tif',x,'Info',acceptor_info);
            acceptor_cell{x} = a;
            b = a;
            b(b>0) = 1;
            cellarea = sum(b(:));
            acceptor_avgIntensity(x) = double(sum(a(:)))./cellarea;
            acceptor_avgIntensity_norm(x) = acceptor_avgIntensity(x)/acceptor_avgIntensity(1);
        end
    end

    %% Photobleach Correction for Donor

    donor_forFit = donor_avgIntensity_norm.';
    % outliers = ~excludedata(plane, donor_forFit, 'range', [0 0.1]); % sets fit exclusion range in Y values (excludedata() with '~', will exclude values inside of range)
    % ['exclude', outliers] <-- add to function below to use outliers
    [fresult,gof] = fit(plane, donor_forFit, 'exp2') % double exponential fit, plane numbers as X and normalized intensity as Y; will display fit paramters and goodness of fit in command window

    fit_donor = fresult(plane); % produce fitted curve using the plane numbers

    CF_donor = 1./fit_donor; % correction factor for donor is 1 over the decay function

    % grab coefficient values from fit to display in command window
    a = num2str(fresult.a); 
    b = num2str(fresult.b); 
    c = num2str(fresult.c); 
    d = num2str(fresult.d); 
    rsq = num2str(gof.rsquare);
    coef1 = sprintf('a = %s ; b = %s', a, b);
    coef2 = sprintf('c = %s ; d = %s', c, d);
    coef3 = sprintf('r^2 = %s', rsq);

    % plot photobleach correction curve for donor
    figure;
    plot(plane, donor_forFit,'rd', plane, fresult(0:I-1),'b-');
    title('Double exponential fit of photobleach correction for donor');
    xlabel('Plane Number');
    ylabel('Normalized Donor Intensity Decay');
    legend('Data', 'Fit');
    axis([0, I, 0, 1.2]);
    text(2, 0.4, 'y = a exp(b*x) + c exp(d*x)');
    text(2, 0.33, coef1);
    text(2, 0.26, coef2);
    text(2, 0.19, coef3);


    %% Photobleach Correction for FRET

    fret_forFit = fret_avgIntensity_norm.';
    % outliers = ~excludedata(plane, fret_forFit, 'range', [0.8 1.2]);  % sets fit exclusion range in Y values (excludedata() with '~', will exclude values inside of range)
    [fresult,gof] = fit(plane, fret_forFit, 'exp2') % double exponential fit, plane numbers as X and normalized intensity as Y; will display fit paramters and goodness of fit in command window

    fitFRET = fresult(plane); % produce fitted curve using the plane numbers

    CF_fret = 1./fitFRET; % correction factor for FRET is 1 over the decay function

    % grab coefficient values from fit to display in command window
    a=num2str(fresult.a);
    b=num2str(fresult.b);
    c=num2str(fresult.c);
    d=num2str(fresult.d);
    rsq=num2str(gof.rsquare);
    coef1 = sprintf('a = %s ; b = %s', a, b);
    coef2 = sprintf('c = %s ; d = %s', c, d);
    coef3 = sprintf('r^2 = %s', rsq);

    % plot photobleach correction curve for donor
    figure;
    plot(plane, fret_forFit,'rd', plane, fresult(0:I-1),'b-');   % Plots results
    title('Double exponential fit of photobleach correction for FRET');
    xlabel('Plane Number');
    ylabel('Normalized FRET Intensity Decay');
    legend('Data', 'Fit');
    axis([0, I, 0, 1.2]);
    text (2, 0.4, 'y = a exp(b*x) + c exp(d*x)');
    text (2, 0.33, coef1);
    text (2, 0.26, coef2);
    text (2, 0.19, coef3);


    %% Photobleach Correction for Acceptor
    if svd == 2
        acceptor_forFit = acceptor_avgIntensity_norm.';
    %     outliers = ~excludedata(plane, acceptor_forFit, 'range', [0 0.1]);  % sets fit exclusion range in Y values (excludedata() with '~', will exclude values inside of range)
        [fresult,gof] = fit(plane, acceptor_forFit, 'exp2') % double exponential fit, plane numbers as X and normalized intensity as Y; will display fit paramters and goodness of fit in command window 

        fit_acceptor = fresult(plane); % produce fitted curve using the plane numbers

        CF_acceptor = 1./fit_acceptor; % correction factor for acceptor is 1 over the decay function

        % grab coefficient values from fit to display in command window
        a = num2str(fresult.a);
        b = num2str(fresult.b);
        c = num2str(fresult.c);
        d = num2str(fresult.d); 
        rsq = num2str(gof.rsquare);
        coef1 = sprintf('a = %s ; b = %s', a, b);
        coef2 = sprintf('c = %s ; d = %s', c, d);
        coef3 = sprintf('r^2 = %s', rsq);

        % plot photobleach correction curve for donor
        figure;
        plot(plane, acceptor_forFit,'rd', plane, fresult(0:I-1),'b-');
        title('Double exponential fit of photobleach correction for acceptor');
        xlabel('Plane Number');
        ylabel('Normalized Acceptor Intensity Decay');
        legend('Data', 'Fit');
        axis([0, I, 0, 1.2]);
        text(2, 0.4, 'y = a exp(b*x) + c exp(d*x)');
        text(2, 0.33, coef1);
        text(2, 0.26, coef2);
        text(2, 0.19, coef3);
    end

    %% Find and Delete Previous Versions of '.tif' Images
    %  In order to write mulitple pages (frames) to a '.tif' requires appending
    %  them during the writing process.  Therefore, it is imperative to delete
    %  previous versions of the '.tif' in order to write a newly processed
    %  '.tif' file.

    % * Tries to find the specific '.tif' files and delete them.
    try  %#ok<*TRYNC>
        delete('donor_pbc.tif');
    end
    try
        delete('fret_pbc.tif');
    end
    try
        delete('acceptor_pbc.tif');
    end

    %% Write Photobleach Corrected Images to '.tif' files
    for x=1:frames
        % Write photobleach corrected donor
        donor_Image = donor_cell{x};
        donor_Image = double(donor_Image);

        donor_pbc = donor_Image.*CF_donor(x);
        donor_pbc = uint16(donor_pbc);

        try 
            imwrite(donor_pbc,'donor_pbc.tif','tif','Compression','none','WriteMode','append');
        catch
            pause(1)
    %         fprintf('DONORpbc Iteration value: %i\n', x);
            imwrite(donor_pbc,'donor_pbc.tif','tif','Compression','none','WriteMode','append');
        end


        % Write photobleach corrected fret
        fret_Image = fret_cell{x};
        fret_Image = double(fret_Image);

        fret_pbc = fret_Image.*CF_fret(x);
        fret_pbc = uint16(fret_pbc);

        try 
            imwrite(fret_pbc,'fret_pbc.tif','tif','Compression','none','WriteMode','append');
        catch
            pause(1)
    %         fprintf('FRETpbc Iteration value: %i\n', x);
            imwrite(fret_pbc,'fret_pbc.tif','tif','Compression','none','WriteMode','append');
        end

        % Write photobleach corrected acceptor
        if svd == 2
            acceptor_Image = acceptor_cell{x};
            acceptor_Image = double(acceptor_Image);

            acceptor_pbc = acceptor_Image.*CF_acceptor(x);
            acceptor_pbc = uint16(acceptor_pbc);

            try 
                imwrite(acceptor_pbc,'acceptor_pbc.tif','tif','Compression','none','WriteMode','append');
            catch
                pause(1)
    %             fprintf('ACCEPTORpbc Iteration value: %i\n', x);
                imwrite(acceptor_pbc,'acceptor_pbc.tif','tif','Compression','none','WriteMode','append');
            end        
        end
    end
end