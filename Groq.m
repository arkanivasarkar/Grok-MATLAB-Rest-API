classdef Groq < handle
    % Groq class interacts with the Groq API to list models and handle chat completions.

    properties
        apikey        % API key for authenticating requests
        systemPrompt  % System message used to set the assistant's behavior
        userPrompt    % History of user messages during a chat
        assistantOutputHistory   % The chat history with the assistant
        model %current selected model
        last_reply
    end
    
    methods
        % Constructor for the Groq class.
        % Arguments:
        %   varargin (optional) - name-value pair inputs (e.g., 'apikey', 'your_api_key')
        %   Sets default values if no input is provided.

        function obj = Groq(varargin)
            % Default values for properties
            obj.apikey = '';  % Empty API key by default
            obj.model = '';
            obj.systemPrompt = {};  % Default system prompt
            obj.userPrompt = {};  % Empty user prompt history
            obj.assistantOutputHistory = {};  % Empty chat history
            obj.last_reply = '';
            
            
            % Parse optional name-value pair inputs using inputParser
            p = inputParser;
            addParameter(p, 'apikey', '', @ischar);  % Validate apikey as a string
            parse(p, varargin{:});
            
            % Set properties based on parsed inputs
            obj.apikey = p.Results.apikey;
        end

        % Method to list available models from the API.
        % Returns a table of model information.
        % Throws an error if the API key is missing or if the request fails.
        function output = listModels(obj)
            % Validate that the API key is provided
            if isempty(obj.apikey)
                error("API key is missing. Please provide a valid API key.");
            end
            
            % URL for fetching models
            url = "https://api.groq.com/openai/v1/models";
            
            % Prepare headers for the request (Authorization)
            headers = ["Authorization", "Bearer " + obj.apikey];
            
            % Set up web options with custom headers
            options = weboptions('HeaderFields', headers);
            
            % Make the web request and process the response
            try
                response = webread(url, options);
                output = response.data;
                % % Convert response data to table format
                % tbl = struct2table(response.data);
            catch ME
                % Handle specific HTTP error codes
                if contains(ME.message, '403')
                    error("Response Code: 403 (Forbidden) - You do not have access.");
                elseif contains(ME.message, '404')
                    error("Response Code: 404 (Not Found) - The requested resource could not be found.");
                elseif contains(ME.message, '401')
                    error("Response Code: 401 (Unauthorized) - Invalid API key.");
                elseif contains(ME.message, '400')
                    error("Response Code: 400 (Bad Request) - Invalid request parameters.");
                else
                    error("Response Code: Unknown - %s", ME.message);
                end
            end
        end

        % Method to send a chat request to the API.
        % Arguments:
        %   model (string)       - Model name to use for the chat.
        %   userPrompt (string)  - User's message to be processed.
        %   systemPrompt (string) - (optional) System message that guides the assistant's behavior.
        %   temperature (double) - Sampling temperature for randomness in response.
        % Returns:
        %   extractedText (string) - The assistant's reply or chat response.
        function extractedText = chat(obj, userPrompt, varargin)
            % extractedText = chat(obj, model, userPrompt, systemPrompt, temperature)
            % Default values for optional inputs using inputParser
            p = inputParser;            
            addRequired(p, 'userPrompt', @ischar);  % userPrompt must be a string
            addParameter(p, 'model', '',@ischar); 
            addParameter(p, 'systemPrompt','', @ischar);  % Default system prompt if not provided
            addParameter(p, 'temperature', 1, @(x) isnumeric(x) && x >= 0 && x <= 2);  % temperature must be between 0 and 2

            parse(p,userPrompt,varargin{:});
            

            if isempty(obj.model) && isempty(p.Results.model)
                error('No model selected'); 
            end

            if ~isempty(p.Results.model)
                obj.model = p.Results.model;
            end
            
            % obj.model

            if isempty(p.Results.systemPrompt)
                systemprompt =  'You are a helpful assistant.';
            else
                 systemprompt =  p.Results.systemPrompt;
            end
            userPrompt = p.Results.userPrompt;
            temperature = p.Results.temperature;

           

            if ~contains(obj.model, {obj.listModels.id})
                error('Model does not match available model list. Please use listModels() property to see which models are available.')
            end

          
            
            % API URL for chat completions
            apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
            
            % Prepare headers for the request (Authorization and Content-Type)
            headers = [
                "Content-Type", "application/json";
                "Authorization", "Bearer " + obj.apikey
            ];
            
            % Create the system message as a struct
            obj.systemPrompt{end+1} = struct('role', 'system', 'content', systemprompt);
            
            % Append the user's prompt to the history
            obj.userPrompt{end + 1} = struct('role', 'user', 'content', userPrompt);

            obj.assistantOutputHistory{end + 1}  = struct('role', 'assistant', 'content', obj.last_reply);
            
            % Combine system message with user history
            messages = [obj.systemPrompt, obj.userPrompt, obj.assistantOutputHistory];
            
            % Prepare the request data as a struct
            data = struct('model', obj.model, 'messages', {messages}, 'temperature', temperature);
            
            % Set up web options with custom headers and media type
            options = weboptions('HeaderFields', headers, 'MediaType', 'application/json');
            
            try
                % Send the request and get the response
                response = webwrite(apiUrl, jsonencode(data), options);

                obj.last_reply = response.choices.message.content;

                obj.last_reply

                extractedText = '';
                
                % % Update the chat history with the assistant's response
                % if isempty(obj.assistantOutputHistory)
                %     obj.assistantOutputHistory = response.choices.message.content;
                % else
                %     obj.assistantOutputHistory = strcat(obj.assistantOutputHistory, '\n', response.choices.message.content);
                % end
                % 
                % % Check if the assistant's response starts with the current chat history
                % if startsWith(response.choices.message.content, obj.assistantOutputHistory) && ~isempty(obj.assistantOutputHistory)
                %     % Extract new part of the response if chat history is a prefix
                %     extractedText = obj.assistantOutputHistory(length(response.choices.message.content) + 1:end);
                % else
                %     % If history is not a prefix, return the entire chat history
                %     extractedText = obj.assistantOutputHistory;
                % end
            catch ME
                % Handle specific HTTP error codes
                if contains(ME.message, '403')
                    error("Response Code: 403 (Forbidden) - You do not have access.");
                elseif contains(ME.message, '404')
                    error("Response Code: 404 (Not Found) - The requested resource could not be found.");
                elseif contains(ME.message, '401')
                    error("Response Code: 401 (Unauthorized) - Invalid API key.");
                elseif contains(ME.message, '400')
                    error("Response Code: 400 (Bad Request) - Invalid request parameters.");
                    elseif contains(ME.message, '429')
                    error("Response Code: 429 (Too Many Requests)");
                    elseif contains(ME.message, '413')
                    error("Response Code: 413 (Request Entity Too Large)");
                else
                    error("Response Code: Unknown - %s", ME.message);      
                end
            end
        end
    end
end
