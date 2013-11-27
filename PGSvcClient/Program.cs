using PGSvcClient.PGSvc;
using System;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text.RegularExpressions;
using System.Xml;
using System.Xml.Xsl;

namespace PGSvcClient
{
  class Program
  {
    static void Main(string[] args) // -o will open the CSV in Excel or default program
    {
      // expects input parameters to be in current directory
      if (!File.Exists("inputs.xml"))
      {
        MakeInputs();
        Environment.Exit(0);
      }

      // NB: recommended pattern in .NET client code does not use a using statement
      // see http://msdn.microsoft.com/en-us/library/aa355056.aspx

      var client = new PopGenSvcClient();
      try
      {
        Inputs inputs;
        using (var reader = XmlReader.Create("inputs.xml"))
        {
          inputs = (new DataContractSerializer(typeof(Inputs))).ReadObject(reader) as Inputs;
        }

        // step 1. initiate task
        var errors = client.Generate(inputs);

        if (errors == null)
        {
          while (true)
          {
            // at the time of writing, the service receive timeout is set to 30s
            // and the session inactivity timeout is set to 10s
            System.Threading.Thread.Sleep(3000);

            // step 2. poll for results ready
            if (client.IsCompleted())
            {
              break;
            }
          }

          // step 3. download results (possibly several megabytes' worth)
          var popGenRes = client.RetrieveResults();
          Write(popGenRes, args.Any(a => a.Equals("-o", StringComparison.InvariantCultureIgnoreCase)));
          Console.WriteLine(popGenRes.Individuals.Length.ToString() + " individual(s) generated");

          // step 4. tell the server we've finished (wait time can be up to 30s)
          var secsToWait = client.CleanUp();
          Console.WriteLine(secsToWait.ToString() + " second(s) to wait");
        }
        else
        {
          Console.WriteLine("Error(s) found in input parameters:");
          Console.WriteLine();
          errors.All((e) =>
          {
            Console.WriteLine(e);
            return true;
          });
          Environment.ExitCode = 1;
        }
      }
      catch (FaultException<PopGenFault> ex)
      {
        Console.WriteLine(ex.Reason);
        Console.WriteLine(ex.Detail.Message);
        client.Abort();
        Environment.ExitCode = 1;
      }
      catch (Exception ex)
      {
        Console.WriteLine(ex.ToString());
        client.Abort();
        Environment.ExitCode = 1;
      }

      if (client.State == CommunicationState.Opened)
      {
        client.Close();
      }
    }

    private static void Write(PopGenRes res, bool open)
    {
      var memoryStream = new MemoryStream();
      using (var writer = XmlWriter.Create(memoryStream))
      {
        (new DataContractSerializer(typeof(PopGenRes))).WriteObject(writer, res);
      }
      memoryStream.Position = 0;

      var pathToMyDocs = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
      var pathToMyData = Path.Combine(pathToMyDocs, "PopGenData");
      DirectoryInfo dirMyData;
      if (!Directory.Exists(pathToMyData))
      {
        dirMyData = Directory.CreateDirectory(pathToMyData);
      }
      else
      {
        dirMyData = new DirectoryInfo(pathToMyData);
      }
      var files = dirMyData.GetFiles("*.csv");
      var fileNo = 0;
      if (files.Count() > 0)
      {
        var name = files.OrderBy(f => f.CreationTime).Last().Name;
        var match = new Regex(@"^[a-z0]*([0-9]*)\.csv$", RegexOptions.IgnoreCase).Match(name);
        if (match.Success)
        {
          Int32.TryParse(match.Groups[1].Value, out fileNo);
        }
      }
      var pathToFile = Path.Combine(pathToMyData, "pgr" + (fileNo + 1).ToString("00000") + ".csv");

      var xsl = new XslCompiledTransform();
      xsl.Load("pgr2csv.xsl");
      using (var reader = XmlReader.Create(memoryStream))
      {
        using (var file = File.OpenWrite(pathToFile))
        {
          xsl.Transform(reader, null, file);
        }
      }

#if DEBUG
      pathToFile = Path.Combine(pathToMyData, "pgr" + (fileNo + 1).ToString("00000") + ".xml");
      File.WriteAllBytes(pathToFile, memoryStream.ToArray());
#endif

      if (open)
      {
        System.Diagnostics.Process.Start(pathToFile);
      }
    }

    private static Inputs MakeInputs()
    {
      var inputs = new Inputs();

      inputs.PopGenUserName = "<approved PopGen user>";
      inputs.PopulationSize = 10;
      inputs.PopulationType = PopulationType.Realistic;
      inputs.Dataset = DatasetName.P3M;
      inputs.AgeLower = 20;
      inputs.AgeUpper = 30;
      inputs.BodyMassIndexLower = 20;
      inputs.BodyMassIndexUpper = 30;
      inputs.HeightLower = 150;
      inputs.HeightUpper = 170;
      inputs.ProbabilityOfMale = 0.5;
      inputs.EthnicityProbabilityBlack = 0.3;
      inputs.EthnicityProbabilityNonBlackOrWhite = 0.3;
      inputs.EthnicityProbabilityWhite = 0.3;
      inputs.EnzymeRateParameter = EnzymeRateParameterType.Vmax;
      inputs.EnzymeRateUnits = EnzymeRateUnitType.PicoMolsPerMinute;
      inputs.FlowUnits = FlowUnitType.MilliLitresPerMinute;

      inputs.IsRichlyPerfusedTissueDiscrete = RichlyPerfused.Brain | RichlyPerfused.Pancreas | RichlyPerfused.Spleen;
      inputs.IsSlowlyPerfusedTissueDiscrete = SlowlyPerfused.Muscle | SlowlyPerfused.Skin;

      inputs.InVitroEnzymeRates = new InVitroEnzymeRate[]
      {
        new InVitroEnzymeRate { Enzyme = "P450", Rate = 123 }
      };

      inputs.Seed = -1;

      using (var writer = XmlWriter.Create("inputs.xml", new XmlWriterSettings { Indent = true, IndentChars = "  " }))
      {
        (new DataContractSerializer(typeof(Inputs))).WriteObject(writer, inputs);
      }

      return inputs;
    }
  }
}
