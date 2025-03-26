# Groq - MATLAB API Client for Groq AI Models  

## Overview  
`Groq` is a MATLAB class that interacts with the Groq API, enabling users to list available AI models and send chat requests.  

## Features  
- ✅ List available AI models from the Groq API  
- ✅ Send chat requests with a system prompt and temperature settings  
- ✅ Maintain chat history within an instance  
- ✅ Handle API errors gracefully  

## Installation  
Ensure you have MATLAB installed. Then, clone this repository:  
```.m
git clone https://github.com/arkanivasarkar/Groq-MATLAB-Rest-API
cd groq-matlab
```

## Usage  
### Initialize the Groq Client
```.m
groq = Groq('apikey', 'your-api-key-here');
```

### List Available Models
```.m
models = groq.listModels();
disp(models);
```

### Send chat request
```.m
groq.chat('Tell me a joke.', 'model', 'llama-2', 'temperature', 0.7);
```


