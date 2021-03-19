using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Azure.WebJobs;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace EW.Sql.Function
{
    public class GetRows
    {
        private const string TimerFormat = @"hh\:mm\:ss";
        private const string ConnectionStringVariable = "SYNAPSE_CONNECTION_STRING";
        private const string RowCountVariable = "SYNAPSE_ROW_COUNT";
        private const string ClientIDVariable = "APP_CLIENT_ID";
        private readonly TelemetryClient telemetryClient;

        /// Using dependency injection will guarantee that you use the same configuration for telemetry collected automatically and manually.
        public GetRows(TelemetryConfiguration telemetryConfiguration)
        {
            this.telemetryClient = new TelemetryClient(telemetryConfiguration);

        }        

        [FunctionName("GetRows")]
        public void Run(
            [TimerTrigger("0 */5 * * * *", RunOnStartup = true, UseMonitor = true)]TimerInfo timer,
            ILogger log
        )
        {
            if (timer.IsPastDue)
            {
                log.LogInformation("Timer is running late!");
            }
            log.LogInformation($"Start processing at: {DateTime.Now}");
            Stopwatch stopwatch = Stopwatch.StartNew();
            int rowCount = GetRowCount(log);
            int rowsRetrieved = 0;

            try {
                using (SqlConnection conn = CreateConnection())
                {
                    conn.Open();
                    log.LogInformation("Connection opened: {0}",stopwatch.Elapsed.ToString(TimerFormat));
                    using (SqlCommand cmd = CreateQueryCommand(conn, log, rowCount))
                    {
                        IAsyncResult result = cmd.BeginExecuteReader(CommandBehavior.CloseConnection);
                        log.LogInformation("Query submitted: {0}",stopwatch.Elapsed.ToString(TimerFormat));

                        while (!result.IsCompleted)
                        {
                            log.LogDebug("Waiting for result: {0}",stopwatch.Elapsed.ToString(TimerFormat));
                            System.Threading.Thread.Sleep(100);
                        }
                        log.LogInformation("Query completed: {0}",stopwatch.Elapsed.ToString(TimerFormat));

                        using (SqlDataReader reader = cmd.EndExecuteReader(result))
                        {
                            while (reader.Read())
                            {
                                if (rowsRetrieved == 0) {
                                    log.LogInformation("First bytes received {0}: ",stopwatch.Elapsed.ToString(TimerFormat));
                                }
                                rowsRetrieved++;

                                // Read all fields
                                for (int i = 0; i < reader.FieldCount; i++)
                                {
                                    reader.GetValue(i);
                                }
                            }
                        }
                        log.LogInformation("{0} rows spooled {0}: ",rowsRetrieved,stopwatch.Elapsed.ToString(TimerFormat));
                    }
                }
            }
            catch (Exception ex)
            {
                log.LogCritical(ex,ex.Message);

                // Rethrow exception
                throw;
            } finally {
                var properties = new Dictionary<string,string> {
                    { "ActivityId",System.Diagnostics.Activity.Current.TraceId.ToString() },
                    { "RowsRequested",rowCount.ToString() },
                    { "RowsRetrieved",rowsRetrieved.ToString() }
                };
                log.LogInformation("ActivityId: {0}",System.Diagnostics.Activity.Current.TraceId.ToString());
                this.telemetryClient.TrackTrace("RunResult",SeverityLevel.Information,properties);
            }
            
            string responseMessage = String.Format("{0} rows were retrieved in {1}",rowsRetrieved,stopwatch.Elapsed.ToString(TimerFormat));
            log.LogInformation(responseMessage);
        }

        private static SqlConnection CreateConnection()
        {
            SqlConnection connection = new SqlConnection(GetConnectionString());

            // Retrieve User Assigned Identity
            string clientId = Environment.GetEnvironmentVariable(ClientIDVariable);
            if (!String.IsNullOrEmpty(clientId)) {
                AzureServiceTokenProvider tokenProvider = new AzureServiceTokenProvider("RunAs=App;AppId=" + clientId);
                // Get AAD token when using SQL Database
                connection.AccessToken = tokenProvider.GetAccessTokenAsync("https://database.windows.net/").Result;
            }

            return connection;
        }

        private static SqlCommand CreateQueryCommand(SqlConnection connection, ILogger log, int rowCount)
        {
            string label = System.Diagnostics.Activity.Current.TraceId.ToString();
            var query = $"select top {rowCount} * from dbo.Trip option (label = '{label}')";
            SqlCommand command = new SqlCommand(query, connection);
            log.LogInformation(command.CommandText);

            return command;
        }

        private static string FormatTimers(Dictionary<string, TimeSpan> timers) {
            string result = String.Empty;

            foreach (string snapshot in timers.Keys) {
                TimeSpan timer = timers[snapshot];
                string elapsed = timer.ToString(TimerFormat);
                result += String.Format("\n{0}: {1}",snapshot,elapsed);
            }

            return result;
        }

        private static string GetConnectionString()
        {

            string connectionString = Environment.GetEnvironmentVariable(ConnectionStringVariable);
            if (String.IsNullOrEmpty(connectionString)) {
                throw new Exception(String.Format("Environment variable {0} not set",ConnectionStringVariable));
            }

            return connectionString;
        }

        private static int GetRowCount(ILogger log)
        {
            var rawValue = Environment.GetEnvironmentVariable(RowCountVariable);

            int rowCount;
            if (Int32.TryParse(rawValue, out rowCount)) {
                return rowCount;
            } else {
                log.LogWarning("SYNAPSE_ROW_COUNT not set to a valid value, assuming value '100'");
                return 100;
            }
        }
    }
}