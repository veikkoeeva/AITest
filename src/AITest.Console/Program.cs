using Microsoft.ML.OnnxRuntimeGenAI;


namespace AITest.Console
{
    //See sample at https://github.com/microsoft/onnxruntime-genai/blob/759333f966f5f94dfd69858a25bf4092c2e286b5/examples/csharp/HelloPhi/Program.cs.

    public static class Program
    {
        public static void Main(string[] args)
        {
            //Get from:
            //https://huggingface.co/EmbeddedLLM/Phi-3-mini-4k-instruct-onnx-cpu-int4-rtn-block-32-acc-level-4/tree/main
            //and note that when downloading the file names need to be changed back to the form
            //shown in the interface.
            string modelPath = @"./cpu-int4-rtn-block-32";
            var model = new Model(modelPath);
            var tokenizer = new Tokenizer(model);            
            var systemPrompt = "You are an AI assistant that helps people find information. Answer questions using a direct style. Do not share more information that the requested by the users.";
            
            System.Console.WriteLine(@"Ask your question. Type an empty string to Exit.");            
            while(true)
            {
                System.Console.WriteLine();

                System.Console.Write(@"Q: ");

                string userQ = System.Console.ReadLine();
                if(string.IsNullOrEmpty(userQ))
                {
                    break;
                }
                
                System.Console.Write("Phi3: ");
                System.Console.WriteLine();                
                var fullPrompt = $"<|system|>{systemPrompt}<|end|><|user|>{userQ}<|end|><|assistant|>";
                var sequences = tokenizer.Encode(fullPrompt);

                var generatorParams = new GeneratorParams(model);
                generatorParams.SetSearchOption("min_length", 50);
                generatorParams.SetSearchOption("max_length", 2048);
                generatorParams.SetSearchOption("past_present_share_buffer", false);
               
                using var generator = new Generator(model, generatorParams);
                generator.AppendTokenSequences(sequences);
                while(!generator.IsDone())
                {                    
                    generator.GenerateNextToken();
                    var outputTokens = generator.GetSequence(0).ToArray();
                    var newToken = new int[1] { outputTokens[^1] };
                    var output = tokenizer.Decode(newToken);
                    System.Console.Write(output);
                }

                _ = System.Console.ReadKey();
            }
        }
    }    
}
