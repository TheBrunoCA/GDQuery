using Godot;
using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Reflection;

public partial class GDQueryBridgeCS : Node
{
    private static readonly Dictionary<string, DbTransaction> _activeTransactions = [];

    static GDQueryBridgeCS()
    {
        TryRegisterProvider(
            providerName: "Microsoft.Data.Sqlite",
            factoryTypeName: "Microsoft.Data.Sqlite.SqliteFactory, Microsoft.Data.Sqlite"
        );
    }

    private static void TryRegisterProvider(
        string providerName, string factoryTypeName)
    {
        try
        {
            var factoryType = Type.GetType(factoryTypeName);
            if (factoryType == null) return;

            var instanceField = factoryType.GetField("Instance", BindingFlags.Public | BindingFlags.Static);
            if (instanceField == null) return;

            var factoryInstance = (DbProviderFactory)instanceField.GetValue(null);
            if (factoryInstance == null) return;

            DbProviderFactories.RegisterFactory(providerName, factoryInstance);
        }
        catch (Exception e)
        {
            GD.PrintErr($"Failed to register provider {providerName}: {e.Message}");
        }
    }

    private static Variant HandleUnknowsType(object value)
    {
        if (value == null) return new Variant();
        try
        {
            string fallbackValue = value.ToString();
            GD.Print($"GDQuery: Non supported type '{value.GetType()}'. Converting to String: '{fallbackValue}'");
            return Variant.From(fallbackValue);
        }
        catch (Exception e)
        {
            GD.PrintErr($"GDQuery: Critical error while converting type '{value.GetType()}'. Returning Nil. Error: {e.Message}");
            return new Variant();
        }
    }

    private static void PopulateCommand(
        DbCommand cmd, Godot.Collections.Dictionary<string, Variant> parameters)
    {
        if (parameters == null || parameters.Count == 0) return;
        foreach (var key in parameters.Keys)
        {
            var param = cmd.CreateParameter();
            param.ParameterName = key.ToString();
            param.Value = parameters[key].Obj ?? DBNull.Value;
            cmd.Parameters.Add(param);
        }
    }

    private static Variant ConvertReaderValue(object value)
    {
        return value switch
        {
            DBNull _ => new Variant(),

            string v => Variant.From(v),
            char v => Variant.From(v.ToString()),

            long v => Variant.From(v),
            int v => Variant.From(v),
            short v => Variant.From(v),
            sbyte v => Variant.From(v),

            ulong v => (v <= long.MaxValue) ? Variant.From((long)v) : Variant.From(v.ToString()),
            uint v => Variant.From((long)v),
            ushort v => Variant.From(v),
            byte v => Variant.From(v),

            double v => Variant.From(v),
            float v => Variant.From(v),
            decimal v => Variant.From((double)v),

            bool v => Variant.From(v),
            Guid v => Variant.From(v.ToString()),
            DateTime v => Variant.From(v.ToString("o")),
            DateTimeOffset v => Variant.From(v.ToString("o")),
            TimeSpan v => Variant.From(v.TotalSeconds),

            byte[] v => Variant.From(v),
            int[] v => Variant.From(v),
            long[] v => Variant.From(v),
            float[] v => Variant.From(v),
            double[] v => Variant.From(v),
            string[] v => Variant.From(v),
            char[] v => Variant.From(new string(v)),

            _ => HandleUnknowsType(value)
        };
    }

    private static T ExecuteInCommandContext<T>(string providerName, string connectionString, string sql,
        Godot.Collections.Dictionary<string, Variant> parameters, string txHandle, Func<DbCommand, T> executeCallback,
        T errorValue)
    {
        try
        {
            if (txHandle != "")
            {
                if (!_activeTransactions.TryGetValue(txHandle, out var tx))
                {
                    GD.PrintErr($"Invalid transaction handle: {txHandle}");
                    return errorValue;
                }
                using var tx_command = tx.Connection.CreateCommand();
                tx_command.Transaction = tx;
                tx_command.CommandText = sql;
                PopulateCommand(tx_command, parameters);
                return executeCallback(tx_command);
            }

            if (!DbProviderFactories.TryGetFactory(providerName, out var factory))
            {
                GD.PrintErr($"Failed to load provider {providerName}");
                return errorValue;
            }

            using var connection = factory.CreateConnection();
            connection.ConnectionString = connectionString;
            connection.Open();

            using var command = connection.CreateCommand();
            command.Connection = connection;
            command.CommandText = sql;
            PopulateCommand(command, parameters);

            return executeCallback(command);
        }
        catch (Exception e)
        {
            GD.PrintErr($"ExecuteContext failed. Error: {e.Message}");
            return errorValue;
        }
    }

    public static int Execute(string providerName, string connectionString, string sql,
        Godot.Collections.Dictionary<string, Variant> parameters, string txHandle)
    {
        return ExecuteInCommandContext(providerName, connectionString, sql, parameters, txHandle, (command) => command.ExecuteNonQuery(), -1);
    }

    public static Variant Scalar(string providerName, string connection, string sql,
        Godot.Collections.Dictionary<string, Variant> parameters, string txHandle)
    {
        return ExecuteInCommandContext(providerName, connection, sql, parameters, txHandle, (command) => ConvertReaderValue(command.ExecuteScalar()), new Variant());
    }

    public static Godot.Collections.Array<Godot.Collections.Dictionary<string, Variant>> Query(string providerName,
        string connectionString, string sql, Godot.Collections.Dictionary<string, Variant> parameters,
        string txHandle)
    {
        return ExecuteInCommandContext(providerName, connectionString, sql, parameters, txHandle,
            (command) =>
            {
                var results = new Godot.Collections.Array<Godot.Collections.Dictionary<string, Variant>>();
                using var reader = command.ExecuteReader();
                while (reader.Read())
                {
                    var row = new Godot.Collections.Dictionary<string, Variant>();
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        row.Add(reader.GetName(i), ConvertReaderValue(reader.GetValue(i)));
                    }

                    results.Add(row);
                }

                return results;
            }, []);
    }

    public static string BeginTransaction(
        string providerName, string connectionString)
    {
        try
        {
            if (!DbProviderFactories.TryGetFactory(providerName, out DbProviderFactory factory))
            {
                GD.PrintErr($"Failed to load provider {providerName}");
                return "";
            }

            var connection = factory.CreateConnection();
            connection.ConnectionString = connectionString;
            connection.Open();

            var transaction = connection.BeginTransaction();
            var handle = Guid.NewGuid().ToString();
            _activeTransactions.Add(handle, transaction);
            return handle;
        }
        catch (Exception e)
        {
            GD.PrintErr($"Failed to begin transaction: {e.Message}");
            return "";
        }
    }

    public static bool CommitTransaction(string txHandle)
    {
        if (!_activeTransactions.TryGetValue(txHandle, out var tx))
        {
            GD.PrintErr($"Invalid transaction handle: {txHandle}");
            return false;
        }
        try
        {
            tx.Commit();
            tx.Dispose();
            _activeTransactions.Remove(txHandle);
            return true;
        }
        catch (Exception e)
        {
            GD.PrintErr($"Failed to commit transaction: {e.Message}");
            tx.Dispose();
            _activeTransactions.Remove(txHandle);
            return false;
        }
    }

    public static bool RollbackTransaction(string txHandle)
    {
        if (!_activeTransactions.TryGetValue(txHandle, out var tx))
        {
            GD.PrintErr($"Invalid transaction handle: {txHandle}");
            return false;
        }

        try
        {
            tx.Rollback();
            tx.Dispose();
            _activeTransactions.Remove(txHandle);
            return true;
        }
        catch (Exception e)
        {
            GD.PrintErr($"Failed to rollback transaction: {e.Message}");
            tx.Dispose();
            _activeTransactions.Remove(txHandle);
            return false;
        }
    }

}
