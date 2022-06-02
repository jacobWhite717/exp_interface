%% PTB setup
% Clear the workspace and the screen
sca;
close all;
clear;

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

% some img locations
img_read_location = 'img/read_splash.png';
img_read = imread(img_read_location);
texture_read = Screen('MakeTexture', window, img_read);

img_rest_location = 'img/rest_splash.png';
img_rest = imread(img_rest_location);
texture_rest = Screen('MakeTexture', window, img_rest);


%% TRIAL PARAMETERS
SUBJECT_NUM = 1;

trial_perms = flip(perms([5, 15, 30, 60]));
trial_perm = trial_perms(SUBJECT_NUM,:);

class_on_task_time = 6*60;
block_time = 6*60;

transition_time = 1;
rest_time = 2;
trigger_buffer_dur = 2;

Screen('TextSize', window, 50);
Screen('TextFont', window, 'TimesNewRoman');

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

block_count = 0;

%% window text setup
text_size = 36;
wrap_num = floor((full_boundary_box(3)-full_boundary_box(1))/text_size * 2.2);
Screen('TextSize', window, text_size);
Screen('TextFont', window, 'Lato');



%% tasks
trigger_timings = [];
latency_timings = [];

for task_num = 1
    trial_dur = trial_perm(task_num);
    text_set = return_text_set(trial_dur);

    num_trials_block = 2;
    num_trials = 2;

    num_blocks = 1;

    % completly randomizing rest/task order, could be changed
    trial_order = [ones(num_trials/2, 1); zeros(num_trials/2, 1)];
    rng(SUBJECT_NUM*10);
    trial_order = trial_order(randperm(length(trial_order)));
    
    %text_folder = sprintf('%is/', trial_dur);
    text_order = 1:round(num_trials/2);
    rng(SUBJECT_NUM*10);
    text_order = text_order(randperm(length(text_order)));
    reading_counter = 1;
    
    % instuction spalsh screen at start of task
    instructions_loc = sprintf('img/%is_instructions.png', trial_dur);
    img_instruct = imread(instructions_loc);
    texture_instruct = Screen('MakeTexture', window, img_instruct);
    Screen('DrawTexture', window, texture_instruct, [], [], 0);
    Screen('Flip', window);
    KbWait([], 3, inf); 

    for i = 1:num_trials
        reading_flag = trial_order(i);

        %% start of queue
        if reading_flag
            Screen('DrawTexture', window, texture_read, [], [], 0);
        else
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
        
        %% start of text
        if reading_flag
            str_num = text_order(reading_counter);
            reading_counter = reading_counter + 1;
            cur_text = char(text_set(str_num));
            DrawFormattedText(window, cur_text, 'wrapat', 'center', light_grey, wrap_num, 0, 0, 1.5, 0, full_boundary_box);
        else
            Screen('DrawLines', window, allCoords, lineWidthPix, light_grey, [xCenter yCenter], 2);
        end
        
        t_latency = tic;
        Screen('Flip', window);
        
        t_trigger = tic;

        latency_timing = toc(t_latency);

        WaitSecs(trial_dur + trigger_buffer_dur); 
        trig_time = toc(t_trigger);
        

        latency_timings = [latency_timings latency_timing];
        trigger_timings = [trigger_timings trig_time];
%         KbWait([], 3, inf);
        
        %% start of rest 
        Screen('FillRect', window, blue_grey);
        Screen('Flip', window);
        WaitSecs(rest_time);
    
        %% end of block splash
        if mod(i, num_trials_block) == 0
            block_count = block_count + 1;
            end_of_block_text = char(sprintf("End of block %i/%i\n\nPlease inform the facilitator that the block has been completed before continuing.\n\nPress any key to continue", block_count, num_blocks*4));
            DrawFormattedText(window, end_of_block_text,...
                    'center', 'center', light_grey, 100, 0, 0, 1.5, 0, full_boundary_box); 
            Screen('Flip', window);
            KbWait([], 3, inf); 
            % KbStrokeWait;
        end
    end
end



%% closing code
sca;


%% helper functions 
function text = return_text_set(duration)
    if duration == 5 
        text = load("text_5s.mat").text_5s;
    elseif duration == 15 
        text = load("text_15s.mat").text_15s;
    elseif duration == 30 
        text = load("text_30s.mat").text_30s;
    elseif duration == 60 
        text = load("text_60s.mat").text_60s;
    end
end


% block trial index (bti) math
function index = bti(block_size, block, trial)
    index = block_size*(block - 1) + trial;
end









