using CommunityToolkit.Maui;
using Microsoft.Extensions.Logging;

namespace AITest
{
    public static class MauiProgram
    {
        public static MauiApp CreateMauiApp()
        {
            var builder = MauiApp.CreateBuilder();
#pragma warning disable CA1416 // Validate platform compatibility
            builder
                .UseMauiApp<App>()
                .UseMauiCommunityToolkitCamera()
                .ConfigureFonts(fonts =>
                {
                    fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                    fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
                });
#pragma warning restore CA1416 // Validate platform compatibility

#if DEBUG
            builder.Logging.AddDebug();
#endif

            return builder.Build();
        }
    }
}
