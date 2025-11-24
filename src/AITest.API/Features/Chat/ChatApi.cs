using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Net.ServerSentEvents;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace AITest.API.Features.Chat
{
    /// <summary>
    /// Contains chat-related endpoint handlers.
    /// This is a static API surface mapped by ChatEndpoints.
    /// </summary>
    public static class ChatApi
    {
        public static async Task<Ok<string>> HandleChatMessageAzureAsync(
            DTOs.ChatMessage chatMessage,
            [FromServices] IChatClient chatClient,
            [FromServices] List<ChatMessage> history,
            CancellationToken cancellationToken)
        {
            var userMessage = new ChatMessage(ChatRole.User, chatMessage.Message);
            history.Add(userMessage);

            var messages = new List<ChatMessage> { userMessage };

            ChatResponse response = await chatClient.GetResponseAsync(messages, null, cancellationToken);

            return TypedResults.Ok("Azure AI: " + (response?.ToString() ?? "No response"));
        }


        public static async Task<IResult> HandleChatMessageLocalAsync(
            DTOs.ChatMessage chatMessage,
            [FromServices] List<ChatMessage> history, CancellationToken cancellationToken)
        {
            var cm = new ChatMessage(ChatRole.User, chatMessage.Message);
            history.Add(cm);


            return await Task.FromResult(TypedResults.Ok("some text" ?? string.Empty));
        }


        /// <summary>
        /// Handles streaming chat responses using Server-Sent Events with typed events.
        /// </summary>
        public static IResult HandleStreamingChatAsync(
            [FromServices] ILogger logger,
            CancellationToken cancellationToken)
        {
            logger.LogInformation("Starting SSE stream for chat");

            return TypedResults.ServerSentEvents(GetChatStreamAsync(logger, cancellationToken));
        }

        /// <summary>
        /// Creates a stream of SSE events with proper event types and JSON data.
        /// </summary>
        private static async IAsyncEnumerable<SseItem<string>> GetChatStreamAsync(
            ILogger logger,
            [EnumeratorCancellation] CancellationToken cancellationToken)
        {
            //Simulate tokens in a chat response...
            var tokens = new[] {
                "Hello",
                ", ",
                "this ",
                "is ",
                "a ",
                "streaming ",
                "response!"
            };

            for(int i = 0; i < tokens.Length; i++)
            {
                if(cancellationToken.IsCancellationRequested)
                {
                    yield break;
                }

                var token = tokens[i];
                logger.LogDebug("Sending token {Index}: {Token}", i, token);

                var tokenEvent = new ChatTokenEvent
                {
                    Content = token,
                    Index = i
                };

                string jsonData = JsonSerializer.Serialize(tokenEvent);
                yield return new SseItem<string>(jsonData, eventType: nameof(ChatTokenEvent));

                try
                {
                    await Task.Delay(TimeSpan.FromMilliseconds(200), cancellationToken);
                }
                catch(OperationCanceledException)
                {
                    yield break;
                }
            }

            if(!cancellationToken.IsCancellationRequested)
            {
                var completionEvent = new ChatCompletionEvent
                {
                    IsComplete = true,
                    TotalTokens = tokens.Length
                };

                string jsonData = JsonSerializer.Serialize(completionEvent);

                yield return new SseItem<string>(jsonData, eventType: nameof(ChatCompletionEvent));
            }

            logger.LogInformation("Successfully completed streaming response");
        }


        /// <summary>
        /// Represents a token in the streaming response
        /// </summary>
        public class ChatTokenEvent
        {
            /// <summary>
            /// The text content of this token
            /// </summary>
            public string Content { get; set; } = string.Empty;

            /// <summary>
            /// The index of this token in the sequence
            /// </summary>
            public int Index { get; set; }
        }

        /// <summary>
        /// Indicates the completion of a streaming response
        /// </summary>
        public class ChatCompletionEvent
        {
            /// <summary>
            /// Whether the response is complete
            /// </summary>
            public bool IsComplete { get; set; }

            /// <summary>
            /// Total number of tokens in the response
            /// </summary>
            public int TotalTokens { get; set; }
        }
    }
}