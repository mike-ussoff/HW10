using System.Text;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Data;
using Npgsql;
using Microsoft.Data.SqlClient;
using Dapper;
using Microsoft.Win32;

namespace ShowPictures
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private void msQueryButton_Click(object sender, RoutedEventArgs e)
        {
            Button button = (Button)sender;
            bool needToBeSaved = button.Name.Equals("msSaveButton");

            string connectionString = msConnectionStringBox.Text;
            string query = msQueryBox.Text;

            try
            {
                if (!string.IsNullOrWhiteSpace(query))
                {
                    using (IDbConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        dynamic? data = conn.Query(query).FirstOrDefault();

                        if (needToBeSaved)
                        {
                            SaveData(data);
                        }
                        else
                        {
                            SetupImage(data);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _ = MessageBox.Show("Error: " + ex.Message, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void SetupImage(dynamic? data)
        {
            if (data == null) throw new ApplicationException("Запрос вернул пустой набор.");

            foreach (var pair in data)
            {
                if (pair.Value == null)
                    throw new ApplicationException($"Поле {pair.Key} не содержит данных");

                if (pair.Value is byte[])
                {
                    byte[]? bytes = pair.Value as byte[];
                    if (bytes != null)
                    {
                        using (var ms = new System.IO.MemoryStream(bytes))
                        {
                            var image = new BitmapImage();
                            image.BeginInit();
                            image.CacheOption = BitmapCacheOption.OnLoad;
                            image.StreamSource = ms;
                            image.EndInit();
                            dbImage.Source = image;
                        }
                    }
                }
                else
                {
                    throw new ApplicationException($"Поле {pair.Key} не содержит бинарных данных");
                }
                break;
            }
        }

        private void SaveData(dynamic? data)
        {
            if (data == null) throw new ApplicationException("Запрос вернул пустой набор.");

            foreach (var pair in data)
            {
                if (pair.Value == null)
                    throw new ApplicationException($"Поле {pair.Key} не содержит данных");

                SaveFileDialog saveFileDialog = new SaveFileDialog();
                saveFileDialog.Filter = "All files (*.*)|*.*";
                saveFileDialog.RestoreDirectory = true;
                if (saveFileDialog.ShowDialog() == false) return;
                string filename = saveFileDialog.FileName;

                if (pair.Value is byte[])
                {
                    byte[]? bytes = pair.Value as byte[];
                    if (bytes != null)
                    {
                        using (FileStream fs = File.Create(filename))
                        {
                            fs.Write(bytes, 0, bytes.Length);
                        }
                    }
                }
                else
                {
                    string ts = pair.Value.ToString();
                    using (StreamWriter writer = new StreamWriter(filename, true))
                    {
                        writer.Write(ts);
                    }
                }
                break;
            }
        }

        private void pgQueryButton_Click(object sender, RoutedEventArgs e)
        {
            Button button = (Button)sender;
            bool needToBeSaved = button.Name.Equals("pgSaveButton");

            string connectionString = pgConnectionStringBox.Text;
            string query = pgQueryBox.Text;

            try
            {
                if (!string.IsNullOrWhiteSpace(query))
                {
                    using (IDbConnection conn = new NpgsqlConnection(connectionString))
                    {
                        conn.Open();

                        dynamic? data = conn.Query(query).FirstOrDefault();

                        if (needToBeSaved)
                        {
                            SaveData(data);
                        }
                        else
                        {
                            SetupImage(data);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _ = MessageBox.Show("Error: " + ex.Message, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }
}