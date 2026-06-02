// Hello-world probe for the WinUI 3 flow.
//
// Boots a minimal WinUI 3 Application, opens a top-level Window, and shows a
// ContentDialog whose body carries the same "WinUI: Application" content the
// previous console build wrote to stdout. The dialog text is derived from
// `typeof(Microsoft.UI.Xaml.Application).Name`, which still forces the
// Microsoft.WinUI projection assembly (shipped by the Microsoft.WindowsAppSDK
// NuGet) to actually load before any UI appears — if the WinAppSDK restore
// was incomplete the typeof below would fail and the dialog would never open.
//
// The app exits as soon as the dialog's close button is clicked.

using System;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace HelloWinUI;

public class App : Application
{
    private Window? _window;

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        var root = new Grid();
        _window = new Window
        {
            Title = "WinUI",
            Content = root,
        };

        root.Loaded += OnRootLoaded;
        _window.Activate();
    }

    private async void OnRootLoaded(object sender, RoutedEventArgs e)
    {
        var root = (FrameworkElement)sender;
        root.Loaded -= OnRootLoaded;

        var dialog = new ContentDialog
        {
            XamlRoot = root.XamlRoot,
            Title = "WinUI",
            Content = $"WinUI: {typeof(Application).Name}",
            CloseButtonText = "OK",
        };

        await dialog.ShowAsync();
        _window?.Close();
        Exit();
    }
}

public static class Program
{
    [STAThread]
    public static void Main()
    {
        Application.Start(p =>
        {
            var context = new DispatcherQueueSynchronizationContext(
                DispatcherQueue.GetForCurrentThread());
            System.Threading.SynchronizationContext.SetSynchronizationContext(context);
            _ = new App();
        });
    }
}
