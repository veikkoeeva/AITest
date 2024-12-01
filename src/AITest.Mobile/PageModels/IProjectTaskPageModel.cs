using AITest.Mobile.Models;
using CommunityToolkit.Mvvm.Input;

namespace AITest.Mobile.PageModels
{
    public interface IProjectTaskPageModel
    {
        IAsyncRelayCommand<ProjectTask> NavigateToTaskCommand { get; }
        bool IsBusy { get; }
    }
}