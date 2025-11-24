
using CommunityToolkit.Maui.Core;

namespace AITest
{
#pragma warning disable CA1416 // Validate platform compatibility
    public partial class MainPage: ContentPage
    {
        private readonly CancellationTokenSource cancelAwake = new();
        private readonly CancellationTokenSource source = new();

        public MainPage()
        {
            InitializeComponent();            
        }


        protected async override void OnAppearing()
        {
            try
            {
                base.OnAppearing();

                var cameras = await _camera.GetAvailableCameras(source.Token);

                //Try to select the front camera if available.
                _camera.SelectedCamera = null;
                foreach(var camera in cameras)
                {
                    if(camera.Position == CameraPosition.Front)
                    {
                        _camera.SelectedCamera = camera;
                        break;
                    }
                }

                //TODO: Maui Toolkit Camera is broken in 2.0.2, it chooses the first on
                //available and it can be e.g. infrared band. Fixed in later, no new package yet.

                //If no front camera was found, select the first available one.
                if(_camera.SelectedCamera == null && cameras.Count > 0)
                {
                    _camera.SelectedCamera = cameras[0];
                }

                try
                {
                    await Task.Delay(6500, cancelAwake.Token);
                }
                catch(TaskCanceledException)
                {
                    //Expected.
                }
            }
            catch(Exception ex)
            {
                Console.WriteLine(ex);
            }
        }


        public async void OnMediaCaptured(object sender, MediaCapturedEventArgs e)
        {
            await Task.CompletedTask;
        }


        void OnMediaCaptureFailed(object sender, MediaCaptureFailedEventArgs e) =>
        Dispatcher.DispatchAsync(async () =>
        {
            await DisplayAlertAsync("Oops!", "Failed to capture image", "OK");
            await GoToIdle();
        });

        async Task GoToIdle()
        {
            await Dispatcher.DispatchAsync(async () =>
            {
                await _camera.StartCameraPreview(source.Token);
            });
        }
    }

#pragma warning disable CA1416 // Validate platform compatibility
}
