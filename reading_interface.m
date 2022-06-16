sca;
close all;
clear;

% Participat setup
SUBJECT_NUM = 1;
SUBJECT_NUM = mod(SUBJECT_NUM-1, 6)+1;

trial_perms = flip(perms([5, 15, 60]));
trial_perm = trial_perms(SUBJECT_NUM,:);

%% PTB video setup
Screen('Preference', 'SkipSyncTests', 1);
% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens'); 

% Draw to the external screen if available
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

% Open a window on screen
blue_grey = [40 44 52]/255;
light_grey = [230 230 230]/255;
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, blue_grey, []);

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Get the size of the on screen window in pixels
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window in pixels
[xCenter, yCenter] = RectCenter(windowRect);
border_size = 100;
full_boundary_box = [border_size, border_size, screenXpixels-border_size, screenYpixels-border_size];
half1_boundary_box = [border_size, border_size, xCenter-(border_size/2), screenYpixels-border_size];
half2_boundary_box = [xCenter+(border_size/2), border_size, screenXpixels-border_size, screenYpixels-border_size];

% make splash textures
img_read_location = 'resources/img/read_splash.png';
img_read = imread(img_read_location);
texture_read = Screen('MakeTexture', window, img_read);

img_rest_location = 'resources/img/rest_splash.png';
img_rest = imread(img_rest_location);
texture_rest = Screen('MakeTexture', window, img_rest);

img_listen_location = 'resources/img/listen_splash.png';
img_listen = imread(img_listen_location);
texture_listen = Screen('MakeTexture', window, img_listen);

% window text setup
text_size = 36;
wrap_num = floor((full_boundary_box(3)-full_boundary_box(1))/text_size * 2.2);
Screen('TextSize', window, text_size);
Screen('TextFont', window, 'Lato');

% cross drawing setup
% Here we set the size of the arms of our fixation cross
fixCrossDimPix = 40;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 4;


%% audio setup
InitializePsychSound(1);
nrchannels = 1;
sampling_rate = 22050;
volume = 0.5;

pahandle = PsychPortAudio('Open', 2, 1, 1, sampling_rate, nrchannels);
PsychPortAudio('Volume', pahandle, volume);


%% Triggerbox / Serial I/O setup
serial_port = 'COM3';  % CHANGE TO APPROPRIATE PORT
baud_rate = 115200;
inter_trigger_interval = 0.005;
tbox = SerialTrigger(serial_port, baud_rate, inter_trigger_interval);


%% TRIAL PARAMETERS
class_on_task_time = 6*60;
block_time = 6*60; % minutes per block here

transition_time = 1;
rest_time = 1;
trigger_buffer_dur = 0; 

block_count = 1;


%% intro eyes open/closed
text = '60 seconds eyes-closed baseline\n\nPress <space> to begin';
DrawFormattedText(window, text,...
        'center', 'center', light_grey, 100, 0, 0, 1.5, 0, full_boundary_box); 
Screen('Flip', window);
KbWait([], 3, inf);

Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter yCenter], 2);
Screen('Flip', window);

tbox.trigger(3);
WaitSecs(60);  
tbox.trigger(5);
% KbWait([], 3, inf);


text = '60 seconds eyes-open baseline\n\nPress <space> to begin';
DrawFormattedText(window, text,...
        'center', 'center', light_grey, 100, 0, 0, 1.5, 0, full_boundary_box); 
Screen('Flip', window);
KbWait([], 3, inf);

Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter yCenter], 2);
Screen('Flip', window);

tbox.trigger(4);
WaitSecs(60);
tbox.trigger(5);
% KbWait([], 3, inf);


%% tasks
trial_timings = [];

for task_num = 1:3
    trial_dur = trial_perm(task_num);
    text_set = return_text_set(trial_dur);

    num_trials_block = block_time / trial_dur;
    num_trials = class_on_task_time / trial_dur * 3; % x3 because of 3 classes
  
    num_blocks = num_trials  / num_trials_block;

    % randomizing class order by block
    full_trial_order = [];
    for i = 1:num_blocks
        block_trial_order = [zeros(num_trials_block/3, 1); ones(num_trials_block/3, 1); 2*ones(num_trials_block/3, 1)];
        rng(SUBJECT_NUM*100+(i-1)*10);
        block_trial_order = block_trial_order(randperm(length(block_trial_order)));
        full_trial_order = [full_trial_order block_trial_order];
    end
    
    text_order = 1:round(num_trials/3);
    rng(SUBJECT_NUM*10);
    text_order = text_order(randperm(length(text_order)));

    audio_order = 1:round(num_trials/3);
    rng(SUBJECT_NUM*11);
    audio_order = audio_order(randperm(length(audio_order)));

    reading_counter = 1;
    listening_counter = 1;
    task_block_counter = 1;
    
    % instuction spalsh screen at start of task
    instructions_loc = sprintf('resources/img/%is_instructions.png', trial_dur);
    img_instruct = imread(instructions_loc);
    texture_instruct = Screen('MakeTexture', window, img_instruct);
    Screen('DrawTexture', window, texture_instruct, [], [], 0);
    Screen('Flip', window);
    KbWait([], 3, inf); 

    for i = 1:num_trials
        reading_flag = full_trial_order(mod(i-1, num_trials_block)+1,task_block_counter) == 1;
        listening_flag = full_trial_order(mod(i-1, num_trials_block)+1,task_block_counter) == 2;
        rest_flag = full_trial_order(mod(i-1, num_trials_block)+1,task_block_counter) == 0;

        %% start of queue
        if reading_flag
            Screen('DrawTexture', window, texture_read, [], [], 0);
        elseif listening_flag
            Screen('DrawTexture', window, texture_listen, [], [], 0);
        else % rest_flag
            Screen('DrawTexture', window, texture_rest, [], [], 0);
        end
        trial_counter_str = sprintf("Task %i / Trial %i", task_num, i);
        Screen('DrawText', window, char(trial_counter_str), 100, 100, light_grey);
        Screen('Flip', window);
        KbWait([], 3, inf);  

        %% start of queue -> text transition
        Screen('FillRect', window, blue_grey);
        Screen('Flip', window);
        WaitSecs(transition_time);
        
        %% start of class trial
        if reading_flag
            str_num = text_order(reading_counter);
            reading_counter = reading_counter + 1;
            cur_text = char(text_set(str_num));
            DrawFormattedText(window, cur_text, 'wrapat', 'center', light_grey, wrap_num, 0, 0, 1.5, 0, full_boundary_box);
        elseif listening_flag
            audio_num = audio_order(listening_counter);
            listening_counter = listening_counter+ 1;
            audio_file = sprintf("resources/audio/%i/%i.mp3", trial_dur, audio_num);
            [audio_vals, ~] = audioread(audio_file);
            PsychPortAudio('FillBuffer', pahandle, audio_vals');
            Screen('DrawLines', window, allCoords, lineWidthPix, light_grey, [xCenter yCenter], 2);
        else
            Screen('DrawLines', window, allCoords, lineWidthPix, light_grey, [xCenter yCenter], 2);
        end
        
        t_start = tic;
        Screen('Flip', window);
        if listening_flag
            PsychPortAudio('Start', pahandle, 1, 0, 1);
        end
        
        %class trigger
        if reading_flag
            tbox.trigger(1);
        elseif listening_flag
            tbox.trigger(6);
        else
            tbox.trigger(2);
        end

        WaitSecs(trial_dur); 

        if listening_flag
            PsychPortAudio('Stop', pahandle);
        end
        t_latency = toc(t_start);

        WaitSecs(trial_dur+1-t_latency);
        
        tbox.trigger(5);
        trial_timings = [trial_timings toc(t_start)];
%         KbWait([], 3, inf);
        
        %% start of rest 
        Screen('FillRect', window, blue_grey);
        Screen('Flip', window);
        WaitSecs(rest_time);
    
        %% end of block splash
        if mod(i, num_trials_block) == 0
            task_block_counter = task_block_counter + 1;
            end_of_block_text = char(sprintf("End of block %i/%i\n\nPlease inform the facilitator that the block has been completed before continuing.\n\nPress any key to continue", block_count, num_blocks*3));
            block_count = block_count + 1;
            DrawFormattedText(window, end_of_block_text,...
                    'center', 'center', light_grey, 100, 0, 0, 1.5, 0, full_boundary_box); 
            Screen('Flip', window);
            KbWait([], 3, inf); 
            % KbStrokeWait;
        end
    end
end


%% outro eyes open/closed
text = '60 seconds eyes-closed baseline\n\nPress <space> to begin';
DrawFormattedText(window, text,...
        'center', 'center', light_grey, 100, 0, 0, 1.5, 0, full_boundary_box); 
Screen('Flip', window);
KbWait([], 3, inf);

Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter yCenter], 2);
Screen('Flip', window);

tbox.trigger(3);
WaitSecs(60);  
tbox.trigger(5);
% KbWait([], 3, inf);


text = '60 seconds eyes-open baseline\n\nPress <space> to begin';
DrawFormattedText(window, text,...
        'center', 'center', light_grey, 100, 0, 0, 1.5, 0, full_boundary_box); 
Screen('Flip', window);
KbWait([], 3, inf);

Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter yCenter], 2);
Screen('Flip', window);

tbox.trigger(4);
WaitSecs(60);
tbox.trigger(5);
% KbWait([], 3, inf);


%% closing code
PsychPortAudio('Close', pahandle);
sca;


%% helper functions 
function text = return_text_set(duration)
    if duration == 5 
        text = load("resources/text/text_5s.mat").text_5s;
    elseif duration == 15 
        text = load("resources/text/text_15s.mat").text_15s;
    elseif duration == 30 
        text = load("resources/text/text_30s.mat").text_30s;
    elseif duration == 60 
        text = load("resources/text/text_60s.mat").text_60s;
    end
end


% block trial index (bti) math
function index = bti(block_size, block, trial)
    index = block_size*(block - 1) + trial;
end









