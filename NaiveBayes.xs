#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "ppport.h"
#include <string>
#include <vector>
#include <map>
#include <cfloat>
#include <cmath>

typedef std::map<std::string, int> StrToIntMap;
typedef std::map<std::string, double> StrToDoubleMap;
typedef std::map<std::string, std::map<std::string, double> > Str2ToDoubleMap;

class NaiveBayes{
  public:
    NaiveBayes();
    ~NaiveBayes();
    void AddDocument(const StrToIntMap &doc, const std::string &label);
    void Train(const double alpha);
    StrToDoubleMap Predict(const StrToIntMap &doc);
  private:
    int numDoc;
    StrToIntMap dict;
    StrToDoubleMap lcount;
    StrToIntMap vcount;
    Str2ToDoubleMap fcount;
    StrToDoubleMap smoother;
};

NaiveBayes::NaiveBayes()
  : numDoc(0), dict(), lcount(), vcount(), fcount()
{
}

NaiveBayes::~NaiveBayes()
{
}

void
NaiveBayes::AddDocument(const StrToIntMap &doc, const std::string &label)
{
  for (StrToIntMap::const_iterator it = doc.begin();
       it != doc.end(); ++it) {
    dict[it->first] += it->second;
    fcount[label][it->first] += it->second;
    vcount[label] += it->second;
  }
  numDoc += 1;
  lcount[label] += 1;

  return;
}

void
NaiveBayes::Train(const double alpha)
{
  int lnum = lcount.size();
  int vnum = dict.size();

  for (StrToDoubleMap::iterator lit = lcount.begin();
       lit != lcount.end(); ++lit) {
    std::string label = lit->first;
    lcount[label] = log(lcount[label] + alpha) - log(numDoc + lnum * alpha);
    smoother[label] = log(alpha) - log(vcount[label] + vnum * alpha);

    for (StrToDoubleMap::iterator fit = (fcount[label]).begin();
         fit != (fcount[label]).end(); ++fit) {
      std::string feature = fit->first;
      fcount[label][feature] = log(fcount[label][feature] + alpha) - log(vcount[label] + vnum * alpha);
    }
  }

  return;
}

StrToDoubleMap
NaiveBayes::Predict(const StrToIntMap &doc)
{
  StrToDoubleMap result;
  double max_score = -DBL_MAX;

  for (StrToDoubleMap::const_iterator lit = lcount.begin();
       lit != lcount.end(); ++lit) {
    std::string label = lit->first;
    result[label] = lcount[label];

    for (StrToIntMap::const_iterator fit = doc.begin();
         fit != doc.end(); ++fit) {
      std::string feature = fit->first;
      double freq = fit->second;

      if (dict.find(feature) == dict.end()) {
        continue;
      }

      if ((fcount[label]).find(feature) != (fcount[label]).end()) {
        result[label] += freq * fcount[label][feature];
      } else {
        result[label] += freq * smoother[label];
      }
    }

    if (result[label] > max_score) {
      max_score = result[label];
    }
  }

  double sum = 0.0;

  for (StrToDoubleMap::iterator lit = lcount.begin();
       lit != lcount.end(); ++lit) {
    std::string label = lit->first;
    result[label] = exp(result[label] - max_score);
    sum += result[label];
  }

  for (StrToDoubleMap::iterator lit = lcount.begin();
       lit != lcount.end(); ++lit) {
    std::string label = lit->first;
    result[label] /= sum;
  }

  return result;
}


MODULE = ToyBox::XS::NaiveBayes		PACKAGE = ToyBox::XS::NaiveBayes	

NaiveBayes *
NaiveBayes::new()

void
NaiveBayes::DESTROY()

void
NaiveBayes::xs_add_instance(attributes_input, label_input)
  SV * attributes_input
  char* label_input
CODE:
  {
    HV *hv_attributes = (HV*) SvRV(attributes_input);
    SV *val;
    char *key;
    I32 retlen;
    int num = hv_iterinit(hv_attributes);
    std::string label = std::string(label_input);
    StrToIntMap attributes;

    for (int i = 0; i < num; ++i) {
      val = hv_iternextsv(hv_attributes, &key, &retlen);
      attributes[key] = (int)SvIV(val);
    }

    THIS->AddDocument(attributes, label);
  }

void
NaiveBayes::xs_train(alpha)
  double alpha
CODE:
  {
    THIS->Train(alpha);
  }

SV*
NaiveBayes::xs_predict(attributes_input)
  SV * attributes_input
CODE:
  {
    HV *hv_attributes = (HV*) SvRV(attributes_input);
    SV *val;
    char *key;
    I32 retlen;
    int num = hv_iterinit(hv_attributes);
    StrToIntMap attributes;
    StrToDoubleMap result;

    for (int i = 0; i < num; ++i) {
      val = hv_iternextsv(hv_attributes, &key, &retlen);
      attributes[key] = (int)SvIV(val);
    }

    result = THIS->Predict(attributes);

    HV *hv_result = newHV();
    for (StrToDoubleMap::iterator it = result.begin();
         it != result.end(); ++it) {
      const char *const_key = (it->first).c_str();
      SV* val = newSVnv(it->second);
      hv_store(hv_result, const_key, strlen(const_key), val, 0); 
    }

    RETVAL = newRV_inc((SV*) hv_result);
  }
OUTPUT:
  RETVAL
  
