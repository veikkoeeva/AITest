using AITest.Mobile.Models;
using AITest.Mobile.PageModels;

namespace AITest.Mobile.Pages
{
    public partial class MainPage: ContentPage
    {
        public MainPage(MainPageModel model)
        {
            InitializeComponent();
            BindingContext = model;
        }
    }
}