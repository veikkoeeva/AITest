namespace AITest.Mobile.Pages
{
    public partial class TaskDetailPage: ContentPage
    {
        public TaskDetailPage(TaskDetailPageModel model)
        {
            InitializeComponent();
            BindingContext = model;
        }
    }
}